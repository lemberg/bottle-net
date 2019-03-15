import tfcoreml
import tensorflow as tf

# Supply a dictionary of input tensors' name and shape (with batch axis)
GRAPH_PB_PATH = './yolov3.pb'
with tf.Session() as sess:
   print("load graph")
   with tf.gfile.FastGFile(GRAPH_PB_PATH,'rb') as f:
       graph_def = tf.GraphDef()
   graph_def.ParseFromString(f.read())
   sess.graph.as_default()
   tf.import_graph_def(graph_def, name='')

   with tf.Graph().as_default() as g:
       tf.import_graph_def(graph_def, name='')

   sess = tf.Session(graph=g)
   OPS = g.get_operations()
   for op in OPS:
       print(op.outputs)

   graph_nodes=[n for n in graph_def.node]
   names = []
   # print(graph_def)
   # for t in graph_nodes:
   #    names.append(t.name)
   # print(names)

input_tensor_shapes = {"input:0": [1, 608, 608, 3]}  # batch size is 1
# TF graph definition
tf_model_path = './yolov3.pb'
# Output CoreML model path
coreml_model_file = './yolov3.mlmodel'
# The TF model's ouput tensor name
output_tensor_names = ['mul_6:0']

# Call the converter. This may take a while
coreml_model = tfcoreml.convert(
    tf_model_path=tf_model_path,
    mlmodel_path=coreml_model_file,
    output_feature_names=output_tensor_names,
    add_custom_layers=True)
