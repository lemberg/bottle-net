import tensorflow as tf
from tensorflow.core.framework import graph_pb2
import time
import operator
import sys


model_pb = "/Users/olehkurnenkov/tensorflow-yolov3/checkpoint/yolov3.pb"
output_txt_file = "./output.txt"
graph_def = graph_pb2.GraphDef()
with open(model_pb, "rb") as f:
    graph_def.ParseFromString(f.read())

tf.import_graph_def(graph_def)

sess = tf.Session()
OPS = sess.graph.get_operations()

ops_dict = {}

# sys.stdout = open(output_txt_file, 'w')
for i, op in enumerate(OPS):
    print(
         '---------------------------------------------------------------------------------------------------------------------------------------------')
    print("{}: op name = {}, op type = ( {} ), inputs = {}, outputs = {}".format(i, op.name, op.type, ", ".join(
          [x.name for x in op.inputs]), ", ".join([x.name for x in op.outputs])))
    print('@input shapes:')
    for x in op.inputs:
          print("name = {} : {}".format(x.name, x.get_shape()))
    print('@output shapes:')
    for x in op.outputs:
        print("name = {} : {}".format(x.name, x.get_shape()))
    if op.type in ops_dict:
          ops_dict[op.type] += 1
    else:
        ops_dict[op.type] = 1

print(
    '---------------------------------------------------------------------------------------------------------------------------------------------')
sorted_ops_count = sorted(ops_dict.items(), key=operator.itemgetter(1))
print('OPS counts:')
for i in sorted_ops_count:
    print("{} : {}".format(i[0], i[1]))
