import numpy as np
import h5py
import imageio
import os
from os import path

def createh5(pathUrl, name):
    images_array = []
    indexes_array = []
    unique_indexes = []

    basePathObjects = os.listdir(pathUrl)
    dirs = [dir for dir in basePathObjects if path.isdir(path.join(pathUrl, dir))]

    for dir in dirs:
        unique_indexes.append(int(dir))
        completeDirPath = pathUrl + dir
        dirObjects = os.listdir(completeDirPath)
        dirObjects = [f for f in dirObjects if not f.startswith('.')]

        for imagePath in dirObjects:
            completeImagePath = pathUrl + dir + "/" + imagePath
            data = imageio.imread(completeImagePath)
            images_array.append(data)
            indexes_array.append(int(dir))

    f = h5py.File(pathUrl + name + ".h5", "w")

    imagesNumpyArray = np.array([np.array(image) for image in images_array])

    m = imagesNumpyArray.shape[0]
    permutation = list(np.random.permutation(m))

    imagesNumpyArray = imagesNumpyArray[permutation, :, :, :]
    xDataSet = f.create_dataset(name+"_set_x", data=imagesNumpyArray, dtype='i8')

    indexesNumpyArray = np.asarray(indexes_array)[permutation]
    yDataSet = f.create_dataset(name+"_set_y", data=indexesNumpyArray)

    unique_indexes_numpy_array = np.asarray(unique_indexes)
    classes_data_set = f.create_dataset("classes", data=unique_indexes_numpy_array)

    f.close()
    return