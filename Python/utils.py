from h5Creator import createh5
import h5py
import numpy as np

basePathTrain = "/Users/olehkurnenkov/Desktop/bottles/Result/train/"
basePathTest = "/Users/olehkurnenkov/Desktop/bottles/Result/test/"

def create_datasets():
    createh5(basePathTrain, "train")
    createh5(basePathTest, "test")

def load_datasets():
    train_set_x, train_set_y, classes = load_dataset("train", basePathTrain)
    test_set_x, test_set_y, _ = load_dataset("test", basePathTest)
    return train_set_x, train_set_y, test_set_x, test_set_y, classes


def load_dataset(name, path):
    dataset = h5py.File(path + name + ".h5")
    set_x = np.array(dataset[name + "_set_x"])
    set_y = np.array(dataset[name + "_set_y"])
    classes = np.array(dataset["classes"])
    return set_x, set_y, classes

def convert_to_one_hot(Y, C):
    Y = np.eye(C)[Y.reshape(-1)].T
    return Y