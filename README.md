# FaceologyFrontend

 An efficient networking connect solution mobile app with facial matching abilities to help users navigate networking events

## Build Instructions

Open Xcode and choose open another project. You will need to use the Faceology.xcworkspace file. 

This project uses the Vision framework in iOS 11 so you need to set the deployment target to iOS 11.0+

Next, you will need to install CocoPods. Then do `pod install --repo-update` in the root directory to install dependencies listed in the podfile.

### Note

The project in this repo is configured with my own LinkedIn API account and signed with my developer account. In order to make your own version, you will need to register for a public LinkedIn API account. 

After registration, follow LinkedIn's [directions](https://developer.linkedin.com/docs/ios-sdk) for its iOS Mobile SDK to configue App's bundle identifier and remember to update the Info.plsit file as well. 

App certificate signing can be done in the `xcodeproj` file. 

## Deploy

This app uses the device's camera so it needs a physical device to run. It also uses deeplinking with LinkedIn so remember to install the LinkedIn native App. 

Simply choose your phone as the deployment target in Run. Your phone should then prompt you to verify the App and you are good to go! 

