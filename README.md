ThatPhoto
=========

ThatPhoto is a new and fun way to flow through and work with the pictures you have on your iPad. Flick, drag, and slide through your camera roll and other albums. 

Integrates with Ink so you can send your photos to other applications.

Features:

* Fly through your photos, spinning the photo wheel to find what you're looking for.
* Add filters and text to make your photos shine.
* Touch-up a picture with red-eye reduction, whitening, and blemish removal using Aviary.
* Work with your photos in other applications using Ink. The new photo will be saved to your camera roll when you're done.

The full list of features is detailed in our [blog post](http://blog.inkmobility.com/post/58830177894/introducing-thatcloud-your-portal-to-your-cloud). **TODO: fix blog post link**

ThatPhoto is also currently available on the [App Store](https://itunes.apple.com/us/app/thatphoto/id681031406)

![ThatPhoto in action](http://a1.mzstatic.com/us/r30/Purple4/v4/bd/07/1a/bd071a85-5bda-e508-65fe-55d3c37c154f/screen480x480.jpeg)

License
-------
ThatPhoto is an open-source iOS application built by [Ink](www.inkmobility.com), released under the MIT License. You are welcome to fork this app, and pull requests are always encouraged.

We do builds every other Thursday and submit the apps to the iOS App Store.


Ink Integration Details
-----------------------
The Ink mobile framework adds the ability to take photos from within ThatPhoto and work with them in other applications. Plus, ThatPhoto can accept photos via Ink, so you can use ThatPhoto to edit images and/or save them to your camera roll. ThatPhoto integrates with Ink in two locations:

  1. ThatPhotoAppDelegate registers incoming actions.
  2. ThatPhotomainViewController provides the handlers for the incoming actions, as well as registers the hooks on the images to open them in the Ink workspace.

What are the "That" Apps?
-------------------------

To demonstrate the power Ink mobile framework, Ink created the "ThatApp" suite of sample apps. Along with ThatPhoto, there is also ThatInbox for reading your mail, ThatPDF for editing your documents and ThatCloud for accessing files stored online. But we want the apps to do more than just showcase the Ink Mobile Framework. That's why we're releasing the apps open source. 

As iOS developers, we leverage an incredible amount of software created by the community. By releasing these apps, we hope we can make small contribution back. Here's what you can do with these apps:
  1. Use them!
    
  They are your aps, and you should be able to do with them what you want. Skin it, fix it, tweak it, improve it. Once you're done, send us a pull request. We build and submit to the app store every other week on Thursdays.
  
  2. Get your code to the app store 

  All of our sample apps are currently in the App store. If you're just learning iOS, you can get real, production code in the app store without having to write an entire app. Just send us a pull request!

  3. Support other iOS Framework companies
  
  If you are building iOS developer tools, these apps are a place where you can integrate your product and show it off to the world. They can also serve to demonstrate different integration strategies to your customers.

  4. Evaluate potential hires
  
  Want to interview an iOS developer? Test their chops by asking them to add a feature or two a real-world app.

  5. Show off your skills
  
  Trying to get a job? Point an employer to your merged pull requests to the sample apps as a demonstration of your ability to contribute to real apps.
  
Contributors
------------
Many thanks to the people who have helped make this app:

* Brett van Zuiden - [@brettcvz](https://github.com/brettcvz)
* Liyan David Chang - [@liyanchang](https://github.com/liyanchang)

Also, the following third-party frameworks are used in this app:

* [Ink iOS Framework](https://github.com/Ink/InkiOSFramework) for connecting to other iOS apps.
* [Aviary iOS Framework](http://www.aviary.com/ios) for editing photos.
* [Apptentive](https://github.com/apptentive/apptentive-ios) for receiving user feedback.