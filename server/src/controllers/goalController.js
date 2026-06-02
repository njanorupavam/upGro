const prisma = require('../services/prisma');

function mapGoal(goal) {
  return {
    id: goal.id,
    title: goal.title,
    description: goal.description,
    targetDate: goal.targetDate,
    progress: goal.progress,
  };
}

function normalizeGoalInput(body) {
  const title = body.title?.trim();
  const description = body.description?.trim() || null;
  const targetDate = body.targetDate ? new Date(body.targetDate) : null;
  const progress = Number(body.progress ?? 0);

  if (!title) {
    return { error: 'Title is required.' };
  }

  if (!Number.isInteger(progress) || progress < 0 || progress > 100) {
    return { error: 'Progress must be between 0 and 100.' };
  }

  if (targetDate && Number.isNaN(targetDate.getTime())) {
    return { error: 'Target date is invalid.' };
  }

  return {
    data: {
      title,
      description,
      targetDate,
      progress,
    },
  };
}

async function listGoals(req, res, next) {
  try {
    const goals = await prisma.goal.findMany({
      where: { userId: req.user.id },
      orderBy: [
        { targetDate: 'asc' },
        { title: 'asc' },
      ],
    });

    return res.status(200).json({ goals: goals.map(mapGoal) });
  } catch (error) {
    return next(error);
  }
}

async function createGoal(req, res, next) {
  try {
    const normalized = normalizeGoalInput(req.body);

    if (normalized.error) {
      return res.status(400).json({ message: normalized.error });
    }

    const goal = await prisma.goal.create({
      data: {
        ...normalized.data,
        userId: req.user.id,
      },
    });

    return res.status(201).json({ goal: mapGoal(goal) });
  } catch (error) {
    return next(error);
  }
}

async function updateGoal(req, res, next) {
  try {
    const normalized = normalizeGoalInput(req.body);

    if (normalized.error) {
      return res.status(400).json({ message: normalized.error });
    }

    const existingGoal = await prisma.goal.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.id,
      },
    });

    if (!existingGoal) {
      return res.status(404).json({ message: 'Goal was not found.' });
    }

    const goal = await prisma.goal.update({
      where: { id: existingGoal.id },
      data: normalized.data,
    });

    return res.status(200).json({ goal: mapGoal(goal) });
  } catch (error) {
    return next(error);
  }
}

async function deleteGoal(req, res, next) {
  try {
    const existingGoal = await prisma.goal.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.id,
      },
    });

    if (!existingGoal) {
      return res.status(404).json({ message: 'Goal was not found.' });
    }

    await prisma.goal.delete({ where: { id: existingGoal.id } });

    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createGoal,
  deleteGoal,
  listGoals,
  updateGoal,
};
