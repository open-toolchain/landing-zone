## SSH Key

An SSH key is needed for access to your IBM Cloud Virtual Server Instances.  This document will show you how to generate an SSH key for both Windows/Linux/Mac

### Windows / Mac / Linux

1. In Windows, open up a Command Prompt.  For Mac and Linux, open up a terminal
2. Type the command:
   ``` 
   ssh-keygen -b 4096 -t rsa
   ```
3. Enter the file in which you would like to save the keys.
4. When it prompts for passphrase, just press `Enter`.
5. You should now have a private and public key file at the location you entered with the filename in step 3 above.  The public key will have the `.pub` extenstion.  You will need the contents of this file for the configuration of Secure Landing Zone.
6. To copy public key for future refercence, Type the command: 
   ```
   pbcopy < ~/.ssh/<name of SSH key>.pub
   ```
