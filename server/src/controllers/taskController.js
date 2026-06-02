const prisma = require('../services/prisma');

const priorities = new Set(['LOW', 'MEDIUM', 'HIGH']);
const statuses = new Set(['TODO', 'IN_PROGRESS', 'COMPLETED']);

function mapTask(task) {
  return {
    id: task.id,
    title: task.title,
    description: task.description,
    priority: task.priority,
    status: task.status,
    dueDate: task.dueDate,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
  };
}

function normalizeTaskInput(body) {
  const title = body.title?.trim();
  const description = body.description?.trim() || null;
  const priority = body.priority || 'MEDIUM';
  const status = body.status || 'TODO';
  const dueDate = body.dueDate ? new Date(body.dueDate) : null;

  if (!title) {
    return { error: 'Title is required.' };
  }

  if (!priorities.has(priority)) {
    return { error: 'Priority is invalid.' };
  }

  if (!statuses.has(status)) {
    return { error: 'Status is invalid.' };
  }

  if (dueDate && Number.isNaN(dueDate.getTime())) {
    return { error: 'Due date is invalid.' };
  }

  return {
    data: {
      title,
      description,
      priority,
      status,
      dueDate,
    },
  };
}

async function listTasks(req, res, next) {
  try {
    const where = { userId: req.user.id };

    if (req.query.status && statuses.has(req.query.status)) {
      where.status = req.query.status;
    }

    if (req.query.priority && priorities.has(req.query.priority)) {
      where.priority = req.query.priority;
    }

    const tasks = await prisma.task.findMany({
      where,
      orderBy: [
        { status: 'asc' },
        { dueDate: 'asc' },
        { createdAt: 'desc' },
      ],
    });

    return res.status(200).json({ tasks: tasks.map(mapTask) });
  } catch (error) {
    return next(error);
  }
}

async function createTask(req, res, next) {
  try {
    const normalized = normalizeTaskInput(req.body);

    if (normalized.error) {
      return res.status(400).json({ message: normalized.error });
    }

    const task = await prisma.task.create({
      data: {
        ...normalized.data,
        userId: req.user.id,
      },
    });

    return res.status(201).json({ task: mapTask(task) });
  } catch (error) {
    return next(error);
  }
}

async function updateTask(req, res, next) {
  try {
    const normalized = normalizeTaskInput(req.body);

    if (normalized.error) {
      return res.status(400).json({ message: normalized.error });
    }

    const existingTask = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.id,
      },
    });

    if (!existingTask) {
      return res.status(404).json({ message: 'Task was not found.' });
    }

    const task = await prisma.task.update({
      where: { id: existingTask.id },
      data: normalized.data,
    });

    return res.status(200).json({ task: mapTask(task) });
  } catch (error) {
    return next(error);
  }
}

async function deleteTask(req, res, next) {
  try {
    const existingTask = await prisma.task.findFirst({
      where: {
        id: req.params.id,
        userId: req.user.id,
      },
    });

    if (!existingTask) {
      return res.status(404).json({ message: 'Task was not found.' });
    }

    await prisma.task.delete({ where: { id: existingTask.id } });

    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createTask,
  deleteTask,
  listTasks,
  updateTask,
};
