const prisma = require('../services/prisma');

function startOfUtcDay(date = new Date()) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function addDays(date, days) {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

async function dashboardAnalytics(req, res, next) {
  try {
    const today = startOfUtcDay();
    const weekStart = addDays(today, -6);

    const [
      totalTasks,
      completedTasks,
      totalHabits,
      habitCheckIns,
      goals,
    ] = await Promise.all([
      prisma.task.count({ where: { userId: req.user.id } }),
      prisma.task.count({
        where: {
          userId: req.user.id,
          status: 'COMPLETED',
        },
      }),
      prisma.habit.count({ where: { userId: req.user.id } }),
      prisma.habitCheckIn.count({
        where: {
          habit: { userId: req.user.id },
          date: { gte: weekStart },
        },
      }),
      prisma.goal.findMany({
        where: { userId: req.user.id },
        select: { progress: true },
      }),
    ]);

    const habitCompletionRate = totalHabits === 0
      ? 0
      : Math.round((habitCheckIns / (totalHabits * 7)) * 100);

    const goalProgress = goals.length === 0
      ? 0
      : Math.round(goals.reduce((sum, goal) => sum + goal.progress, 0) / goals.length);

    return res.status(200).json({
      analytics: {
        tasksCompleted: completedTasks,
        totalTasks,
        taskCompletionRate: totalTasks === 0
          ? 0
          : Math.round((completedTasks / totalTasks) * 100),
        habitCompletionRate,
        goalProgress,
      },
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { dashboardAnalytics };
