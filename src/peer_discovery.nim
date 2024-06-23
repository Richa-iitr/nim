import tables, strutils, os, random, net

const
  K = 20        # Bucket size
  IDLength = 160 # Length of the node ID in bits

type
  NodeID = array[IDLength div 8, byte]
  Peer = ref object
    id: NodeID
    address: string
  Bucket = seq[Peer]

  KademliaNode = ref object
    id: NodeID
    buckets: seq[Bucket]

proc generateRandomID(): NodeID =
  var id: NodeID
  for i in 0..<len(id):
    id[i] = byte(rand(256))
  return id

proc xorDistance(a, b: NodeID): NodeID =
  var dist: NodeID
  for i in 0..<len(a):
    dist[i] = a[i] xor b[i]
  return dist

proc countLeadingZeros(x: byte): int =
  var n = 0
  var y = x
  while y != 0:
    y = y shr 1
    n += 1
  return 8 - n

proc leadingZeros(x: NodeID): int =
  for i in 0..<len(x):
    if x[i] != 0:
      return i * 8 + countLeadingZeros(x[i])
  return len(x) * 8

proc newKademliaNode(): KademliaNode =
  KademliaNode(id: generateRandomID(), buckets: newSeq[Bucket](IDLength))

proc `<`(a, b: NodeID): bool =
  for i in 0..<a.len:
    if a[i] < b[i]:
      return true
    if b[i] < a[i]:
      return false
  return false

proc `<`(a, b: Peer): bool =
  return a.id < b.id

proc findBucketIndex(localID, remoteID: NodeID): int =
  let dist = xorDistance(localID, remoteID)
  return leadingZeros(dist)

proc addPeer(node: KademliaNode, peer: Peer) =
  let index = findBucketIndex(node.id, peer.id)
  var bucket = node.buckets[index]
  if peer notin bucket:
    if len(bucket) < K:
      bucket.add(peer)
    else:
      bucket.delete(0)
      bucket.add(peer)
  node.buckets[index] = bucket

proc lookup(node: KademliaNode, targetID: NodeID): seq[Peer] =
  var result: seq[Peer]
  let index = findBucketIndex(node.id, targetID)
  for i in 0..<len(node.buckets):
    result.add(node.buckets[(index + i) mod len(node.buckets)])
    if len(result) >= K:
      break
  return result

# For demonstration, we create a few nodes and perform a peer discovery

proc main() =
  let node1 = newKademliaNode()
  let node2 = newKademliaNode()
  let node3 = newKademliaNode()

  addPeer(node1, Peer(id: node2.id, address: "127.0.0.1:5001"))
  addPeer(node1, Peer(id: node3.id, address: "127.0.0.1:5002"))

  let peers = lookup(node1, node2.id)
  echo "Peers found:"
  for peer in peers:
    echo peer.address

main()
