rem don't forget to accept the EULA or it won't boot
rem don't remove the nogui as it might cause lag issues
java -Xms6G -Xmx6G -Dfml.readTimeout=180 @java9args.txt -jar lwjgl3ify-forgePatches.jar nogui
pause
