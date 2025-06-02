# Microsoft Defender for Endpoint on NixOS

This flake allows you to run Microsoft Defender for Endpoint (also known as Microsoft Defender Advanced Threat Protection) on NixOS.

Please feel free to submit the package and module to nixpkgs if you are willing to maintain the package!

> [!WARNING]  
> This is an unofficial repackaging of Microsoft's Defender for Endpoint package. [Microsoft states in their deployment process guide that:](https://learn.microsoft.com/en-us/defender-endpoint/linux-installer-script#deployment-process)
>
> > Repackaging the Defender for Endpoint installation package isn't a supported scenario. Doing so can negatively affect the integrity of the product and lead to adverse results, including but not limited to triggering tampering alerts and updates failing to apply.
>
> It is your responsibility to check that Defender for Endpoint correctly runs on your machine. I am not responsible for any impact to the security of your device, nor is anyone else who maintains or contributes to this repository.

## Installation

1. Add this repo as a flake input in your flake.nix.
2. Add the flake's module to your target system's modules.
3. In your system configuration, set `services.mdatp.enable` to `true`. Here's an example flake:

   ```nix
   {
     description = "My system flake";

     inputs = {
       # ...
         nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
         mdatp = {
         url = "github:NitorCreations/nix-mdatp";
         inputs.nixpkgs.follows = "nixpkgs";
         };
     };

     outputs = {
       self,
       # ...
       mdatp
     }:
     {
       nixosConfigurations."my-device" = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         modules = [
           # ...
           mdatp.nixosModules.mdatp
           {
             services.mdatp.enable = true;
           }
         ];
       };
     };
   ```

4. Acquire the [Onboarding script](https://learn.microsoft.com/en-us/defender-endpoint/linux-install-manually#download-the-onboarding-package) for your organization and run it.
5. Follow the [Client configuration](https://learn.microsoft.com/en-us/defender-endpoint/linux-install-manually#download-the-onboarding-package) instructions for enabling Real Time Protection.
