"""This profile sets up a cluster of servers ready to generate LDBC SNB
datasets.

Instructions:
TBD
"""

import geni.aggregate.cloudlab as cloudlab
import geni.portal as portal
import geni.rspec.pg as pg
import geni.urn as urn

# === Parameters for this profile ===
# Directory where CloudLab remote datasets will be mounted (on NFS server).
remote_blockstore_mount_point = "/remote"
# Local blockstore partition on each server.
local_blockstore_mount_point = "/local/store"
# NFS shared home directory for all users.
nfs_shared_home_dir = "/shome"
# NFS directory for sharing mounted datasets.
nfs_shared_datasets_dir = "/datasets"

# Portal context is where parameters and the rspec request is defined.
pc = portal.Context()

# The possible set of base disk-images that this cluster can be booted with.
# The second field of every tupule is what is displayed on the cloudlab
# dashboard.
images = [ ("UBUNTU14-64-STD", "Ubuntu 14.04") ]

# The possible set of node-types this cluster can be configured with. Currently 
# only m510 machines are supported.
hardware_types = [ ("m510", "m510 (CloudLab Utah, Intel Xeon-D)") ]

pc.defineParameter("image", "Disk Image",
        portal.ParameterType.IMAGE, images[0], images,
        "Specify the base disk image that all the nodes of the cluster " +\
        "should be booted with.")

pc.defineParameter("hardware_type", "Hardware Type", 
        portal.ParameterType.NODETYPE, hardware_types[0], hardware_types)

pc.defineParameter("username", "Username", 
        portal.ParameterType.STRING, "", None,
        "Username for which all user-specific software will be configured.")

pc.defineParameter("num_nodes", "Number of Hadoop Worker Nodes",
        portal.ParameterType.INTEGER, 3, [])

pc.defineParameter("dataset_urns", "Datasets", 
        portal.ParameterType.STRING, "", None,
        "Space separated list of datasets to mount. All datasets are " +\
        "mounted on master at " + remote_blockstore_mount_point)

params = pc.bindParameters()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

# Create a local area network for the Hadoop cluster.
clan = request.LAN("clan")
clan.best_effort = True
clan.vlan_tagging = True
clan.link_multiplexing = True

# Create a special network for connecting datasets to NFS
dslan = request.LAN("dslan")
dslan.best_effort = True
dslan.vlan_tagging = True
dslan.link_multiplexing = True

# Create array of the requested datasets
dataset_urns = params.dataset_urns.split(" ")

for i in range(len(dataset_urns)):
    dataset_urn = dataset_urns[i]
    dataset_name = dataset_urn[dataset_urn.rfind("+") + 1:]
    rbs = request.RemoteBlockstore(
            "dataset%02d" % (i + 1), 
            remote_blockstore_mount_point + "/" + dataset_name, 
            "if1")
    rbs.dataset = dataset_urn
    dslan.addInterface(rbs.interface)

# Setup hostnames
hostnames = ["master", "nfs"]
for i in range(params.num_nodes):
    hostnames.append("n%02d" % (i + 1))

for host in hostnames:
    node = request.RawPC(host)
    node.hardware_type = params.hardware_type
    node.disk_image = urn.Image(cloudlab.Utah, "emulab-ops:%s" % params.image)

    # Allocate the rest of the space on disk for a local storage partition. The
    # hadoop nodes use this for storing HDFS data, and the NFS server uses it
    # to store users shared home directories. 
    localbs = node.Blockstore(host + "localbs", local_blockstore_mount_point)
    localbs.size = "200GB"

    # All hosts are on the client LAN. 
    clan.addInterface(node.addInterface("if1"))

    # Run setup script after experiment instantiation.
    node.addService(pg.Execute(shell="sh", 
        command="sudo /local/repository/setup.sh %s %s %s %s %s" % \
        (local_blockstore_mount_point, 
        remote_blockstore_mount_point, 
        nfs_shared_home_dir,
        nfs_shared_datasets_dir,
        params.username)))

    # In the case of the NFS server, add it to the dataset LAN so that it can
    # export these datasets to the reset of the servers in the cluster.
    if host == "nfs":
        dslan.addInterface(node.addInterface("if2"))

# Print the RSpec to the enclosing page.
pc.printRequestRSpec(request)

