@echo off
REM Script: seed-db.bat
REM Purpose: Populate database with test data (Windows)
REM Usage: scripts\seed-db.bat

echo.
echo ========================================
echo   Seeding APS Database
echo ========================================
echo.

REM Load environment variables
if exist .env (
    for /f "tokens=1,2 delims==" %%a in ('type .env ^| findstr /v "^#"') do (
        set %%a=%%b
    )
) else (
    set POSTGRES_USER=apsadmin
    set POSTGRES_PASSWORD=adminpassword
    set POSTGRES_DB=apartment_booking
)

echo Database: %POSTGRES_DB%
echo User: %POSTGRES_USER%
echo.

REM Check if container is running
docker ps | findstr aps-postgres >nul 2>&1
if errorlevel 1 (
    echo ERROR: PostgreSQL container 'aps-postgres' is not running.
    echo.
    echo Please start it with:
    echo   docker-compose up -d
    echo.
    pause
    exit /b 1
)

echo Running seed files...
echo.

REM Run each seed file
for %%f in (seeds\*.sql) do (
    echo    - Seeding: %%~nxf
    docker exec -i aps-postgres psql -U %POSTGRES_USER% -d %POSTGRES_DB% < "%%f"
    if errorlevel 1 (
        echo ERROR: Seed failed: %%~nxf
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo   Database seeded successfully!
echo ========================================
echo.
echo Data summary:
docker exec -it aps-postgres psql -U %POSTGRES_USER% -d %POSTGRES_DB% -c "SELECT 'Users' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'Facilities', COUNT(*) FROM facilities UNION ALL SELECT 'Bookings', COUNT(*) FROM bookings;"
echo.
pause