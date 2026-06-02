const prisma = require('../services/prisma');

function startOfUtcDay(date = new Date()) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function addDays(date, days) {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function dateKey(date) {
  return startOfUtcDay(date).toISOString().slice(0, 10);
}

function weeklyProgress(checkIns) {
  const today = startOfUtcDay();
  const checkedDates = new Set(checkIns.map((checkIn) => dateKey(checkIn.date)));

  return Array.from({ length: 7 }, (_, index) => {
    const date = addDays(today, index - 6);
    return {
      date: dateKey(date),
      completed: checkedDates.has(dateKey(date)),
    };
  });
}

async function recalculateStreaks(habitId) {
  const checkIns = await prisma.habitCheckIn.findMany({
    where: { habitId },
    orderBy: { date: 'desc' },
  });

  const checkedDates = new Set(checkIns.map((checkIn) => dateKey(checkIn.date)));
  let cursor = startOfUtcDay();
  let currentStreak = 0;

  while (checkedDates.has(dateKey(cursor))) {
    currentStreak += 1;
    cursor = addDays(cursor, -1);
  }

  let bestStreak = 0;
  let runningStreak = 0;
  let previousDate = null;

  for (const checkIn of [...checkIns].reverse()) {
    const currentDate = startOfUtcDay(checkIn.date);

    if (previousDate && dateKey(currentDate) === dateKey(addDays(previousDate, 1))) {
      runningStreak += 1;
    } else {
      runningStreak = 1;
    }

    bestStreak = Math.max(bestStreak, runningStreak);
    previousDate = currentDate;
  }

  return prisma.habit.update({
    where: { id: habitId },
    data: { currentStreak, bestStreak },
    include: {
      checkIns: {
        where: { date: { gte: addDays(startOfUtcDay(), -6) } },
        orderBy: { date: 'asc' },
      },
    },
  });
}

function mapHabit(habit) {
  const checkIns = habit.checkIns || [];

  return {
    id: habit.id,
    title: habit.title,
    description: habit.description,
    currentStreak: habit.currentStreak,
    bestStreak: habit.bestStreak,
    checkedInToday: checkIns.some((checkIn) => dateKey(checkIn.date) === dateKey(new Date())),
    weeklyProgress: weeklyProgress(checkIns),
  };
}

async function listHabits(req, res, next) {
  try {
    const habits = await prisma.habit.findMany({
      where: { userId: req.user.id },
      orderBy: { title: 'asc' },
      include: {
        checkIns: {
          where: { date: { gte: addDays(startOfUtcDay(), -6) } },
          orderBy: { date: 'asc' },
        },
      },
    });

    return res.status(200).json({ habits: habits.map(mapHabit) });
  } catch (error) {
    return next(error);
  }
}

async function createHabit(req, res, next) {
  try {
    const title = req.body.title?.trim();
    const description = req.body.description?.trim() || null;

    if (!title) {
      return res.status(400).json({ message: 'Title is required.' });
    }

    const habit = await prisma.habit.create({
      data: {
        title,
        description,
        userId: req.user.id,
      },
      include: { checkIns: true },
    });

    return res.status(201).json({ habit: mapHabit(habit) });
  } catch (error) {
    return next(error);
  }
}

async function updateHabit(req, res, next) {
  try {
    const title = req.body.title?.trim();
    const description = req.body.description?.trim() || null;

    if (!title) {
      return res.status(400).json({ message: 'Title is required.' });
    }

    const existingHabit = await prisma.habit.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.id,
      },
    });

    if (!existingHabit) {
      return res.status(404).json({ message: 'Habit was not found.' });
    }

    const habit = await prisma.habit.update({
      where: { id: existingHabit.id },
      data: { title, description },
      include: {
        checkIns: {
          where: { date: { gte: addDays(startOfUtcDay(), -6) } },
          orderBy: { date: 'asc' },
        },
      },
    });

    return res.status(200).json({ habit: mapHabit(habit) });
  } catch (error) {
    return next(error);
  }
}

async function deleteHabit(req, res, next) {
  try {
    const existingHabit = await prisma.habit.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.id,
      },
    });

    if (!existingHabit) {
      return res.status(404).json({ message: 'Habit was not found.' });
    }

    await prisma.habit.delete({ where: { id: existingHabit.id } });

    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
}

async function checkInHabit(req, res, next) {
  try {
    const existingHabit = await prisma.habit.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.id,
      },
    });

    if (!existingHabit) {
      return res.status(404).json({ message: 'Habit was not found.' });
    }

    await prisma.habitCheckIn.upsert({
      where: {
        habitId_date: {
          habitId: existingHabit.id,
          date: startOfUtcDay(),
        },
      },
      update: {},
      create: {
        habitId: existingHabit.id,
        date: startOfUtcDay(),
      },
    });

    const habit = await recalculateStreaks(existingHabit.id);

    return res.status(200).json({ habit: mapHabit(habit) });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  checkInHabit,
  createHabit,
  deleteHabit,
  listHabits,
  updateHabit,
};
