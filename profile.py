"""This profile sets up a cluster of servers ready to generate LDBC SNB
datasets.

Instructions:
TBD
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg

import geni.urn as urn
import geni.aggregate.cloudlab as cloudlab

# Create a portal context.
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

hardware_types = [ ("m510", "m510 (CloudLab Utah, Intel Xeon-D)"),
                   ("m400", "m400 (CloudLab Utah, 64-bit ARM)"),
                   ("c220g2", "c220g2 (CloudLab Wisconsin, Two Intel E5-2660 v3)") ]

images = [ ("UBUNTU14-64-STD", "Ubuntu 14.04"),
           ("UBUNTU15-04-64-STD", "Ubuntu 15.04"),
           ("UBUNTU16-64-STD", "Ubuntu 16.04")]

# Create configuration parameter for the number of client nodes.
num_nodes = range(0,1000)

pc.defineParameter("hardware_type", "Hardware Type",
                   portal.ParameterType.NODETYPE, 
                   hardware_types[0], hardware_types)

pc.defineParameter("image", "Disk Image",
        portal.ParameterType.IMAGE, images[0], images)

pc.defineParameter("num_nodes", "Number of Hadoop Worker Nodes", 
    portal.ParameterType.INTEGER, 1, num_nodes)

pc.defineParameter("dataset_urn", "URN for Dataset Storage",
    portal.ParameterType.STRING, "")

params = pc.bindParameters()

node_names = ["master"]
for i in range(params.num_nodes):
  node_names.append("n%02d" % (i + 1))

# Setup a LAN for the clients
if num_nodes > 0:
  clan = request.LAN("clan")
  clan.best_effort = True
  clan.vlan_tagging = True
  clan.link_multiplexing = True

# Setup a LAN just for the dataset blockstore
datasetbslan = request.LAN("dslan")
datasetbslan.best_effort = True
datasetbslan.vlan_tagging = True
datasetbslan.link_multiplexing = True

for name in node_names:
  node = request.RawPC(name)
  node.hardware_type = params.hardware_type
  if node.hardware_type == "c220g2":
    node.disk_image = urn.Image(cloudlab.Wisconsin,"emulab-ops:%s" % params.image)
  else:
    node.disk_image = urn.Image(cloudlab.Utah,"emulab-ops:%s" % params.image)

  # Ask for a 200GB file system mounted at /local/hadoop
  # This is for all hadoop related data
  localbs = node.Blockstore(name + "localbs", "/local/hadoop")
  if node.hardware_type == "c220g2":
    localbs.size = "1000GB"
  else:
    localbs.size = "200GB"

  node.addService(pg.Execute(shell="sh", 
      command="sudo /local/repository/setup-all.sh"))

  if num_nodes > 0:
    iface = node.addInterface("if1")
    clan.addInterface(iface)

  if name == "master":
    datasetbs = request.RemoteBlockstore("datasetbs", "/mnt/dataset", "if1")
    datasetbs.dataset = params.dataset_urn
    datasetbslan.addInterface(datasetbs.interface)
    datasetbsiface = node.addInterface("if2")
    datasetbslan.addInterface(datasetbsiface)
    
    node.addService(pg.Execute(shell="sh", 
        command="sudo /local/repository/setup-master.sh"))

# Print the RSpec to the enclosing page.
pc.printRequestRSpec(request)

