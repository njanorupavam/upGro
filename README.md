# DayForge

DayForge is a personal productivity operating system built with Flutter, Express, Prisma, and Supabase PostgreSQL.

## Current MVP Progress

- Authentication with JWT
- Task management
- Habit tracking with streaks
- Goal tracking with progress
- Dashboard summaries
- Analytics charts
- Responsive Material 3 app shell

## Local URLs

- Frontend preview: `http://127.0.0.1:5173`
- Backend API: `http://127.0.0.1:4000`
- Backend health: `http://127.0.0.1:4000/health`

## Frontend

```powershell
D:\workstuff\devtools\flutter\bin\flutter.bat build web --no-wasm-dry-run
```

The checked-in static preview helper serves `build/web`:

```powershell
cd D:\workstuff\Projects\Web\dayforge
node server/static-web.js
```

## Backend

```powershell
cd D:\workstuff\Projects\Web\dayforge\server
npm start
```

Required local environment variables live in `server/.env`, which is intentionally ignored by Git.

```env
DATABASE_URL="..."
DIRECT_URL="..."
JWT_SECRET="..."
```

## Phase Roadmap

Completed:

- Phase 0: Project initialization
- Phase 1: Database design
- Phase 2: Authentication
- Phase 3: App shell
- Phase 4: Task management
- Phase 5: Habit tracker
- Phase 6: Goal tracking
- Phase 7: Dashboard
- Phase 8: Analytics
- Phase 9: Polishing

Remaining:

- Phase 10: Deployment
