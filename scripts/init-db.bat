@echo off
REM Script: init-db.bat
REM Purpose: Initialize database with migrations (Windows)
REM Usage: scripts\init-db.bat

echo.
echo ========================================
echo   Initializing APS Database
echo ========================================
echo.

REM Load environment variables from .env
if exist .env (
    for /f "tokens=1,2 delims==" %%a in ('type .env ^| findstr /v "^#"') do (
        set %%a=%%b
    )
    echo Environment variables loaded from .env
) else (
    echo WARNING: .env file not found. Using defaults.
    set POSTGRES_USER=apsadmin
    set POSTGRES_PASSWORD=adminpassword
    set POSTGRES_DB=aps_db
    set POSTGRES_HOST=localhost
    set POSTGRES_PORT=5432
)

echo.
echo Database: %POSTGRES_DB%
echo Host: %POSTGRES_HOST%:%POSTGRES_PORT%
echo User: %POSTGRES_USER%
echo.

REM Check if Docker container is running
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

echo Running migrations...
echo.

REM Run each migration file
for %%f in (migrations\*.sql) do (
    echo    - Running: %%~nxf
    docker exec -i aps-postgres psql -U %POSTGRES_USER% -d %POSTGRES_DB% < "%%f"
    if errorlevel 1 (
        echo ERROR: Migration failed: %%~nxf
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo   Database initialized successfully!
echo ========================================
echo.
echo To verify, run:
echo   docker exec -it aps-postgres psql -U %POSTGRES_USER% -d %POSTGRES_DB% -c "\dt"
echo.
pause