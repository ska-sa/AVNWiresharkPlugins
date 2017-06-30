--  Protocol dissector for AVN ROACH-based pulsar instrument.
avn_pulsar_proto = Proto("AVNPulsar", "AVN Pulsar Protocol")

-- First SPEAD byte
local f_magic_no = ProtoField.uint8("AVNPulsar.magic_no", "SPEAD Magic Number", base.HEX)
local f_version = ProtoField.uint8("AVNPulsar.version", "SPEAD version", base.DEC)
local f_item_pointer_width = ProtoField.uint8("AVNPulsar.item_pointer_width", "SPEAD Item Pointer Width (bytes)", base.DEC)
local f_heap_addr_width = ProtoField.uint8("AVNPulsar.heap_addr_width", "SPEAD Heap Address Width (bytes)", base.DEC)
local f_reserved = ProtoField.uint16("AVNPulsar.reserved", "Reserved for future use.", base.DEC)
local f_items = ProtoField.uint16("AVNPulsar.items", "Number of items", base.DEC)

-- SPEAD misc
-- This should really be 1 bit and 23 bits, but wireshark's limitations mean we have to make a bit of a hack
local f_spead_direct = ProtoField.uint8("AVNPulsar.spead_direct", "Directly / Indirectly addressed", base.HEX)
local f_spead_id = ProtoField.uint16("AVNPulsar.spead_id", "Spead item ID", base.HEX)
local f_spead_data = ProtoField.uint32("AVNPulsar.spead_data", "Spead item data/address", base.HEX)


local f_spead_generic = ProtoField.uint64("AVNPulsar.speadfield", "Generic SPEAD field", base.HEX)

local f_data = ProtoField.uint64("AVNPulsar.data", "Sample data", base.HEX)

avn_pulsar_proto.fields = {f_magic_no, f_version, f_item_pointer_width, f_heap_addr_width, f_reserved, f_items, f_data, f_spead_direct,f_spead_id, f_spead_generic, f_spead_data}

function avn_pulsar_proto.dissector(buffer,pinfo,tree)
  pinfo.cols.protocol = "AVN_PULSAR"
  local subtree = tree:add(avn_pulsar_proto,buffer(),"AVN Pulsar Protocol Data")
  subtree:add(f_magic_no, buffer(0,1))
  subtree:add(f_version, buffer(1,1))
  subtree:add(f_item_pointer_width, buffer(2,1))
  subtree:add(f_heap_addr_width, buffer(3,1))
  subtree:add(f_reserved, buffer(4,2))
  num_items = buffer(6,2):uint()
  subtree:add(f_items, num_items)

  for spead_item=0,num_items-1,1
  do
    subtree:add(f_spead_direct, buffer(8 + spead_item*8, 1))
    subtree:add(f_spead_id, buffer(9 + spead_item*8, 2))
    subtree:add(f_spead_data, buffer(12 + spead_item*8, 4))
  end

  header_size = (num_items+1) * 8

  data_size = (buffer:len()-header_size) / 8

  for data_sample = 0, data_size-1, 1
  do
    subtree:add(f_data, buffer(header_size + data_sample*8,8))
  end
end

udp_table = DissectorTable.get("udp.port")


udp_table:add(60000,avn_pulsar_proto)

