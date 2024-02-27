"""
Profile for our CSCI 555L project

Instructions:
Wait for the experiment to start, and then log into one or more of the nodes
by clicking on them in the toplogy, and choosing the `shell` menu option.
Use `sudo` to run root commands.
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
# Emulab specific extensions.
import geni.rspec.emulab as emulab

# Create a portal context, needed to defined parameters
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

# 1 master, 3 workers, and 1 client to run the measurements from
# HDFS default replication factor is 3, so 3 workers makes sense
nodeCount = 5


# Ubuntu 22.04
# osImage = ('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU22-64-STD', 'UBUNTU 22.04')
osImage = 'urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU22-64-STD'

# Physical type for all nodes
# This is a parameter we will enter
pc.defineParameter("phystype",  "Optional physical node type",
                   portal.ParameterType.STRING, "",
                   longDescription="Specify a single physical node type (pc3000,d710,etc) " +
                   "instead of letting the resource mapper choose for you.")

# Start VNC, why not
# "There will be a menu option in the node context menu to start a browser based VNC client"
startVNC = True


# For now, not setting link speed manually
# Optional link speed, normally the resource mapper will choose for you based on node availability
"""
pc.defineParameter("linkSpeed", "Link Speed",portal.ParameterType.INTEGER, 0,
                   [(0,"Any"),(100000,"100Mb/s"),(1000000,"1Gb/s"),(10000000,"10Gb/s"),(25000000,"25Gb/s"),(100000000,"100Gb/s")],
                   advanced=True,
                   longDescription="A specific link speed to use for your lan. Normally the resource " +
                   "mapper will choose for you based on node availability and the optional physical type.")

# For very large lans you might to tell the resource mapper to override the bandwidth constraints
# and treat it a "best-effort"
pc.defineParameter("bestEffort",  "Best Effort", portal.ParameterType.BOOLEAN, False,
                    advanced=True,
                    longDescription="For very large lans, you might get an error saying 'not enough bandwidth.' " +
                    "This options tells the resource mapper to ignore bandwidth and assume you know what you " +
                    "are doing, just give me the lan I ask for (if enough nodes are available).")
"""

# Require all nodes on the same switch, for replicability
# Note that this option can make it impossible for your experiment to map.
sameSwitch = True

# Retrieve the values the user specifies during instantiation.
# This is just the hardware type
params = pc.bindParameters()

# Check parameter validity.
if params.phystype != "":
    tokens = params.phystype.split(",")
    if len(tokens) != 1:
        pc.reportError(portal.ParameterError("Only a single type is allowed", ["phystype"]))

pc.verifyParameters()

# Create link/lan.
lan = request.LAN()
if sameSwitch:
	lan.setNoInterSwitchLinks()

""" This is for the currently unused option to request a set bandwidth
    if params.bestEffort:
        lan.best_effort = True
    elif params.linkSpeed > 0:
        lan.bandwidth = params.linkSpeed
"""

# Process nodes, adding to link or lan.
for i in range(nodeCount):
    # Create a node and add it to the request
    if i == 0:
        name = "master"
    elif i == 3:
        name = "client"
    else:
        name = "worker_" + str(i)
    node = request.RawPC(name)
    node.disk_image = osImage

    # Add to lan
    if nodeCount > 1:
        iface = node.addInterface("eth1")
        lan.addInterface(iface)
        pass
    # Optional hardware type.
    if params.phystype != "":
        node.hardware_type = params.phystype
        pass
    # Install and start X11 VNC. Calling this informs the Portal that you want a VNC
    # option in the node context menu to create a browser VNC client.
    #
    # If you prefer to start the VNC server yourself (on port 5901) then add nostart=True.
    #
    if startVNC:
        node.startVNC()
        pass
    pass

# Print the RSpec to the enclosing page.
pc.printRequestRSpec(request)