# image_cutter

This is a task to create a Flutter application that takes an input image, divides it into smaller parts, and replaces each part with an image from a pre-defined dataset based on the average color of each part.

To complete this task, the following functional requirements need to be met:

    Upload image: The application should allow the user to upload an image from their device.

    Calculate average RGB for each tile image: The application should calculate the average RGB for each image in the dataset that will be used to replace the parts of the input image.

    Divide input image into parts: The input image should be divided into smaller parts, with each part being the same size.

    Calculate average RGB for each part of the input image: The application should calculate the average RGB for each part of the input image.

    Calculate the distance between every tile and every part of the image: The application should calculate the distance between the average RGB of each tile image and the average RGB of each part of the input image using Delta E* CIE.

    Choose tiles with the smallest distance: The application should choose the tiles with the smallest distance and resize them to fit the part of the input image they are replacing.

    Display output image: The application should display the output image with the replaced tiles.

The following resources will be used:

    An image dataset located at [https://data.caltech.edu/records/mzrjq-6wc02]
    Delta E* CIE formula for calculating the distance between colors.

One limitation is that the application should not use the Euclidean distance formula for calculating color distances. Instead, the Delta E* CIE formula should be used to take human color perception into account.

Upon completion, the work should be added to a Git repository with a descriptive README file. 
The repository can be made public, or the interviewers can be added as contributors if it is kept.
    
    []: # Path: lib/main.dart
Lebogang Moholo

