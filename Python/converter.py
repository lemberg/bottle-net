# Conversion script for tiny-yolo-voc to Core ML.
# Needs Python 2.7 and Keras 1.2.2

import coremltools

coreml_model = coremltools.converters.keras.convert('resnet-50.h5',
                                                    input_names='input1',
                                                    image_input_names='input1',
                                                    output_names=['output1'],
                                                    input_name_shape_dict={'input1': [None, 64, 64, 3]},
                                                    image_scale=1/255.)

coreml_model.input_description['input1'] = 'Input image'
coreml_model.output_description['output1'] = 'Class'

coreml_model.author = 'Original paper: Kaiming He, Xiangyu Zhang, Shaoqing Ren, Jian Sun'
coreml_model.license = 'Public Domain'
coreml_model.short_description = "ResNet-50 model"

coreml_model.save('resnet50.mlmodel')
