docker build -t umn-filesystem .

docker run -v C:\DockerMount:C:\BuildOutput -it --name umn-filesystem -w C:\pester umn-filesystem:latest powershell.exe -file .\build\build.ps1

docker container stop umn-filesystem

docker rm -f umn-filesystem
