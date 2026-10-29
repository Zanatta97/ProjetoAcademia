@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"

rem Atualiza no repo pai o commit para o qual cada submodule aponta.
rem Rode depois de commitar e dar push em algum dos filhos.

set "FILHOS=ProjetoAcademiaAPI ProjetoAcademiaFront"
set "ERRO=0"

echo.
echo === Conferindo os repos filhos ===
for %%F in (%FILHOS%) do call :verificar %%F
if "%ERRO%"=="1" goto :falhou

echo.
echo === Atualizando o repo pai ===
git add .gitmodules %FILHOS%
if errorlevel 1 goto :falhou

git diff --cached --quiet -- .gitmodules %FILHOS%
if not errorlevel 1 (
    echo Nenhum submodule mudou. Nada para commitar.
    goto :push
)

rem Commita só os submodules, mesmo que haja outra coisa em stage no pai.
git commit -m "chore: atualiza submodules" -- .gitmodules %FILHOS%
if errorlevel 1 goto :falhou

:push
git rev-parse --verify HEAD >nul 2>&1
if errorlevel 1 (
    echo O repo pai ainda não tem commit. Nada para enviar.
    goto :fim
)
git push -u origin main
if errorlevel 1 goto :falhou

echo.
echo Pronto: repo pai atualizado.
goto :fim

rem ------------------------------------------------------------------
rem Confere um filho e registra como submodule se ainda não estiver.
:verificar
set "FILHO=%~1"
echo.
echo [%FILHO%]

if not exist "%FILHO%\.git" (
    echo   ERRO: %FILHO% não é um repositório git.
    set "ERRO=1"
    goto :eof
)

git -C "%FILHO%" rev-parse --verify HEAD >nul 2>&1
if errorlevel 1 (
    echo   ERRO: %FILHO% ainda não tem nenhum commit.
    set "ERRO=1"
    goto :eof
)

git -C "%FILHO%" rev-parse --abbrev-ref --symbolic-full-name @{u} >nul 2>&1
if errorlevel 1 (
    echo   ERRO: a branch de %FILHO% não tem upstream. Rode "git push -u origin main" nele.
    set "ERRO=1"
    goto :eof
)

set "ADIANTE=0"
for /f %%N in ('git -C "%FILHO%" rev-list --count @{u}..HEAD') do set "ADIANTE=%%N"
if not "%ADIANTE%"=="0" (
    echo   ERRO: %FILHO% tem %ADIANTE% commit^(s^) sem push. Dê push nele antes.
    set "ERRO=1"
    goto :eof
)

git -C "%FILHO%" diff --quiet HEAD >nul 2>&1
if errorlevel 1 echo   Aviso: há alterações sem commit em %FILHO%. Elas não entram no pai.

git config -f .gitmodules --get "submodule.%FILHO%.path" >nul 2>&1
if not errorlevel 1 (
    echo   OK
    goto :eof
)

set "URL="
for /f "delims=" %%U in ('git -C "%FILHO%" remote get-url origin') do set "URL=%%U"
if "%URL%"=="" (
    echo   ERRO: %FILHO% não tem remote origin.
    set "ERRO=1"
    goto :eof
)

rem Registra sem "git submodule add": ele roda pelo sh.exe do Git, que trava
rem no fork com o hook do Avecto. Os comandos abaixo são nativos e gravam o
rem mesmo .gitmodules, .git/config e gitlink que o submodule add gravaria.
echo   Registrando como submodule: %URL%
git config -f .gitmodules "submodule.%FILHO%.path" "%FILHO%" || goto :erro_registro
git config -f .gitmodules "submodule.%FILHO%.url" "%URL%" || goto :erro_registro
git config "submodule.%FILHO%.url" "%URL%" || goto :erro_registro
git config "submodule.%FILHO%.active" true || goto :erro_registro
git -c advice.addEmbeddedRepo=false add "%FILHO%" || goto :erro_registro
goto :eof

:erro_registro
echo   ERRO: não foi possível registrar %FILHO% como submodule.
set "ERRO=1"
goto :eof

rem ------------------------------------------------------------------
:falhou
echo.
echo Nada foi enviado. Corrija o que está acima e rode de novo.

:fim
echo.
pause
endlocal
