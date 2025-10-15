@echo off
echo Downloading Urdu Fonts...
mkdir assets\fonts 2>nul

echo Downloading Regular font...
curl -L -o assets\fonts\NotoNastaliqUrdu-Regular.ttf https://raw.githubusercontent.com/google/fonts/main/ofl/notonastaliqurdu/NotoNastaliqUrdu-Regular.ttf

echo Downloading Bold font...
curl -L -o assets\fonts\NotoNastaliqUrdu-Bold.ttf https://raw.githubusercontent.com/google/fonts/main/ofl/notonastaliqurdu/NotoNastaliqUrdu-Bold.ttf

echo Done! 