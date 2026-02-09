@echo off
REM Script: reset-db.bat
REM Purpose: Drop and recreate database (WARNING: destructive) (Windows)
REM Usage: scripts\reset-db.bat

echo.
echo ========================================
echo   WARNING: DATABASE RESET
echo ========================================
echo.
echo This will DESTROY all data in the database!
echo.
set /p confirm="Are you sure? Type 'yes' to confirm: "

if not "%confirm%"=="yes" (
    echo.
    echo Aborted.
    pause
    exit /b 0
)

REM Load environment variables
if exist .env (
    for /f "tokens=1,2 delims==" %%a in ('type .env ^| findstr /v "^#"') do (
        set %%a=%%b
    )
) else (
    set POSTGRES_USER=apsadmin
    set POSTGRES_PASSWORD=adminpassword
    set POSTGRES_DB=aps_db
)

echo.
echo Dropping database: %POSTGRES_DB%
docker exec -it aps-postgres psql -U %POSTGRES_USER% -d postgres -c "DROP DATABASE IF EXISTS %POSTGRES_DB%;"

echo.
echo Creating database: %POSTGRES_DB%
docker exec -it aps-postgres psql -U %POSTGRES_USER% -d postgres -c "CREATE DATABASE %POSTGRES_DB%;"

echo.
echo ========================================
echo   Database reset complete!
echo ========================================
echo.
echo Now run migrations:
echo   scripts\init-db.bat
echo.
echo Then seed data:
echo   scripts\seed-db.bat
echo.
pause