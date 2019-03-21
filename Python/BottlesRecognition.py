import numpy as np
from keras import optimizers
from keras import layers
from keras.layers import Input, Add, Dense, Activation, ZeroPadding2D, BatchNormalization, Flatten, Conv2D, AveragePooling2D, MaxPooling2D, GlobalMaxPooling2D
from keras.models import Model, load_model
from keras.preprocessing import image
from keras.utils import layer_utils
from keras.utils.data_utils import get_file
from keras.applications.imagenet_utils import preprocess_input
import pydot
from IPython.display import SVG
from keras.utils.vis_utils import model_to_dot
from keras.utils import plot_model
from resnets_utils import *
from keras.initializers import glorot_uniform
import scipy.misc
import matplotlib as mpl
mpl.use('TkAgg')
import matplotlib.pyplot as plt
from matplotlib.pyplot import imshow

import utils

import keras.backend as K
K.set_image_data_format('channels_last')
K.set_learning_phase(1)


class BottlesRecognizer:

    def __init__(self):
        return


    def identity_block(self, X, f, filters, stage, block):
        """

        Arguments:
        X -- input tensor of shape (m, n_H_prev, n_W_prev, n_C_prev)
        f -- integer, specifying the shape of the middle CONV's window for the main path
        filters -- python list of integers, defining the number of filters in the CONV layers of the main path
        stage -- integer, used to name the layers, depending on their position in the network
        block -- string/character, used to name the layers, depending on their position in the network

        Returns:
        X -- output of the identity block, tensor of shape (n_H, n_W, n_C)
        """

        # defining name basis
        conv_name_base = 'res' + str(stage) + block + '_branch'
        bn_name_base = 'bn' + str(stage) + block + '_branch'

        # Retrieve Filters
        F1, F2, F3 = filters

        X_shortcut = X

        # First component of main path
        X = Conv2D(filters=F1, kernel_size=(1, 1), strides=(1, 1), padding='valid', name=conv_name_base + '2a',
                   kernel_initializer=glorot_uniform(seed=0))(X)
        X = BatchNormalization(axis=3, name=bn_name_base + '2a')(X)
        X = Activation('relu')(X)


        X = Conv2D(filters=F2, kernel_size=(f, f), strides=(1, 1), padding='same', name=conv_name_base + '2b',
                   kernel_initializer=glorot_uniform(seed=0))(X)
        X = BatchNormalization(axis=3, name=bn_name_base + '2b')(X)
        X = Activation('relu')(X)

        X = Conv2D(filters=F3, kernel_size=(1, 1), strides=(1, 1), padding='valid', name=conv_name_base + '2c',
                   kernel_initializer=glorot_uniform(seed=0))(X)
        X = BatchNormalization(axis=3, name=bn_name_base + '2c')(X)

        X = Add()([X, X_shortcut])
        X = Activation('relu')(X)


        return X

    def convolutional_block(self, X, f, filters, stage, block, s=2):
        """
        Arguments:
        X -- input tensor of shape (m, n_H_prev, n_W_prev, n_C_prev)
        f -- integer, specifying the shape of the middle CONV's window for the main path
        filters -- python list of integers, defining the number of filters in the CONV layers of the main path
        stage -- integer, used to name the layers, depending on their position in the network
        block -- string/character, used to name the layers, depending on their position in the network
        s -- Integer, specifying the stride to be used

        Returns:
        X -- output of the convolutional block, tensor of shape (n_H, n_W, n_C)
        """

        # defining name basis
        conv_name_base = 'res' + str(stage) + block + '_branch'
        bn_name_base = 'bn' + str(stage) + block + '_branch'

        # Retrieve Filters
        F1, F2, F3 = filters

        # Save the input value
        X_shortcut = X

        X = Conv2D(F1, (1, 1), strides=(s, s), padding='valid', name=conv_name_base + '2a',
                   kernel_initializer=glorot_uniform(seed=0))(X)
        X = BatchNormalization(axis=3, name=bn_name_base + '2a')(X)
        X = Activation('relu')(X)



        X = Conv2D(F2, (f, f), strides=(1, 1), padding='same', name=conv_name_base + '2b',
                   kernel_initializer=glorot_uniform(seed=0))(X)
        X = BatchNormalization(axis=3, name=bn_name_base + '2b')(X)
        X = Activation('relu')(X)

        X = Conv2D(F3, (1, 1), strides=(1, 1), padding='valid', name=conv_name_base + '2c',
                   kernel_initializer=glorot_uniform(seed=0))(X)
        X = BatchNormalization(axis=3, name=bn_name_base + '2c')(X)

        X_shortcut = Conv2D(F3, (1, 1), strides=(s, s), padding='valid', name=conv_name_base + '1',
                            kernel_initializer=glorot_uniform(seed=0))(X_shortcut)
        X_shortcut = BatchNormalization(axis=3, name=bn_name_base + '1')(X_shortcut)

        X = Add()([X, X_shortcut])

        X = Activation('relu')(X)

        return X


    def ResNet50(self, input_shape=(64, 64, 3), classes=5):
        """
        Implementation of the popular ResNet50 the following architecture:
        CONV2D -> BATCHNORM -> RELU -> MAXPOOL -> CONVBLOCK -> IDBLOCK*2 -> CONVBLOCK -> IDBLOCK*3
        -> CONVBLOCK -> IDBLOCK*5 -> CONVBLOCK -> IDBLOCK*2 -> AVGPOOL -> TOPLAYER

        Arguments:
        input_shape -- shape of the images of the dataset
        classes -- integer, number of classes

        Returns:
        model -- a Model() instance in Keras
        """

        # Define the input as a tensor with shape input_shape
        X_input = Input(input_shape)

        # Zero-Padding
        X = ZeroPadding2D((3, 3))(X_input)

        # Stage 1
        X = Conv2D(64, (7, 7), strides=(2, 2), name='conv1', kernel_initializer=glorot_uniform(seed=0))(X)
        X = BatchNormalization(axis=3, name='bn_conv1')(X)
        X = Activation('relu')(X)
        X = MaxPooling2D((3, 3), strides=(2, 2))(X)

        # Stage 2
        X = self.convolutional_block(X, f=3, filters=[64, 64, 256], stage=2, block='a', s=1)
        X = self.identity_block(X, 3, [64, 64, 256], stage=2, block='b')
        X = self.identity_block(X, 3, [64, 64, 256], stage=2, block='c')


        X = self.convolutional_block(X, f=3, filters=[128, 128, 512], stage=3, block='a', s=2)
        X = self.identity_block(X, 3, [128, 128, 512], stage=3, block='b')
        X = self.identity_block(X, 3, [128, 128, 512], stage=3, block='c')
        X = self.identity_block(X, 3, [128, 128, 512], stage=3, block='d')

        X = self.convolutional_block(X, f=3, filters=[256, 256, 1024], stage=4, block='a', s=2)
        X = self.identity_block(X, 3, [256, 256, 1024], stage=4, block='b')
        X = self.identity_block(X, 3, [256, 256, 1024], stage=4, block='c')
        X = self.identity_block(X, 3, [256, 256, 1024], stage=4, block='d')
        X = self.identity_block(X, 3, [256, 256, 1024], stage=4, block='e')
        X = self.identity_block(X, 3, [256, 256, 1024], stage=4, block='f')

        X = self.convolutional_block(X, f=3, filters=[512, 512, 2048], stage=5, block='a', s=2)
        X = self.identity_block(X, 3, [512, 512, 2048], stage=5, block='b')
        X = self.identity_block(X, 3, [512, 512, 2048], stage=5, block='c')

        X = AveragePooling2D(pool_size=(2, 2), name='avg_pool')(X)


        # output layer
        X = Flatten()(X)
        X = Dense(classes, activation='softmax', name='fc' + str(classes), kernel_initializer=glorot_uniform(seed=0))(X)

        # Create model
        model = Model(inputs=X_input, outputs=X, name='ResNet50')

        return model

    def trainResNet50(self, should_save_weights = False):
        model = self.ResNet50(input_shape=(64, 64, 3), classes=5)

        self.train_model(model, should_save_weights=should_save_weights)

        return

    def train_existing_model(self, should_save_weights = False):
        model = load_model("resnet-50.h5")
        self.train_model(model, should_save_weights=should_save_weights)

    def train_model(self, model, should_save_weights = False):
        optimizer = optimizers.Adam(lr=0.001, beta_1=0.9, beta_2=0.999, epsilon=None, decay=0.0, amsgrad=False)

        model.compile(optimizer='Adam', loss='categorical_crossentropy', metrics=['accuracy'])
        X_train_orig, Y_train_orig, X_test_orig, Y_test_orig, classes = utils.load_datasets()

        # Normalize image vectors
        X_train = X_train_orig / 255.
        X_test = X_test_orig / 255.

        Y_train = utils.convert_to_one_hot(Y_train_orig, 5).T
        Y_test = utils.convert_to_one_hot(Y_test_orig, 5).T

        print ("number of training examples = " + str(X_train.shape[0]))
        print ("number of test examples = " + str(X_test.shape[0]))
        print ("X_train shape: " + str(X_train.shape))
        print ("Y_train shape: " + str(Y_train.shape))
        print ("X_test shape: " + str(X_test.shape))
        print ("Y_test shape: " + str(Y_test.shape))

        model.fit(X_train, Y_train, epochs=10, batch_size=32)

        preds = model.evaluate(X_test, Y_test)
        print ("Loss = " + str(preds[0]))
        print ("Test Accuracy = " + str(preds[1]))

        model.save("resnet-50.h5")

        if should_save_weights:
            model.save_weights("resnet-50.weights.h5")

    def testModel(self):
        model = load_model("resnet-50_100.h5")

        X_train_orig, Y_train_orig, X_test_orig, Y_test_orig, classes = utils.load_datasets()
        X_train = X_train_orig / 255.
        X_test = X_test_orig / 255.

        Y_train = utils.convert_to_one_hot(Y_train_orig, 5).T
        Y_test = utils.convert_to_one_hot(Y_test_orig, 5).T

        predsTest = model.evaluate(X_test, Y_test)
        predsTrain = model.evaluate(X_train, Y_train)

        print ("Test Loss = " + str(predsTest[0]))
        print ("Test Accuracy = " + str(predsTest[1]))
        print ("Train Loss = " + str(predsTrain[0]))
        print ("Train Accuracy = " + str(predsTrain[1]))

net = BottlesRecognizer()
# net.testModel()
net.train_existing_model()