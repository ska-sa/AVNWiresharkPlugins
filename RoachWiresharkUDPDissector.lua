-- Protocol dissector for AVN Roach based SDR instruments include Spectrometers and ADC data streamer

avn_roach_proto = Proto("AVNRoach","AVN Roach Protocol")

local f_magic_no	= ProtoField.uint32("AVNRoach.magic_no", 		"Magic number", 	base.HEX)
local f_timestamp_us 	= ProtoField.int64("AVNRoach.timestamp_us", 		"Timestamp (us)", 	base.DEC)
local f_timestamp_local = ProtoField.absolute_time("AVNRoach.timestamp_local",  "Timestamp (local)",    base.LOCAL)
local f_sequence_no 	= ProtoField.uint8("AVNRoach.sequence_no", 		"Sequence number", 	base.DEC)
local f_n_sequence_nos  = ProtoField.uint8("AVNRoach.n_sequence_nos", 		"N sequency numbers", 	base.DEC)
local f_noise_diode_on 	= ProtoField.uint8("AVNRoach.noise_diode_on", 		"Noise diode on", 	base.DEC)
local f_instrument_type	= ProtoField.string("AVNRoach.instrument_type", 	"Instrument Type", 	base.NONE)
local f_data    	= ProtoField.bytes("AVNRoach.data", 			"Sample data", 		base.HEX)

avn_roach_proto.fields = {f_magic_no, f_timestamp_us, f_timestamp_local, f_sequence_no, f_n_sequence_nos, f_noise_diode_on, f_instrument_type, f_data}

local msg_types = {
    [0]  = {"WB_SPECTROMETER_CFFT", "Wideband spectrometer - complex FFT data"},
    [1]  = {"WB_SPECTROMETER_LRQU", "Wideband spectrometer - left power, right power, Stokes Q, Stokes U"},
    [2]  = {"NB_SPECTROMETER_CFFT", "Wideband spectrometer - complex FFT data"},
    [3]  = {"NB_SPECTROMETER_LRQU", "Wideband spectrometer - left power, right power, Stokes Q, Stokes U"},
    [4]  = {"TIME_SAMPLE_STREAM",   "Time domain samples"}
};

function avn_roach_proto.dissector(buffer,pinfo,tree)
    pinfo.cols.protocol = "AVN_ROACH"
    local subtree = tree:add(avn_roach_proto,buffer(),"AVN ROACH Protocol Data")
    subtree:add(f_magic_no, 		buffer(0,4))
    subtree:add(f_timestamp_us, 	buffer(4,8))

    --Create NSTime structure
    local usecs 			= buffer(4,8):int64()
    local secs  			= (usecs / 1000000):tonumber()
    local nsecs 			= (usecs % 1000000):tonumber() * 1000
    local nstime 			= NSTime.new(secs, nsecs)
    subtree:add(f_timestamp_local,      nstime)

    subtree:add(f_sequence_no,		buffer(12,1))
    subtree:add(f_n_sequence_nos,	buffer(13,1))
    subtree:add(f_noise_diode_on, 	buffer(14,2):bitfield(0,1))
    subtree:add(f_instrument_type,	msg_types[buffer(14,2):bitfield(1,15)][2])
    subtree:add(f_data,			buffer(16,buffer:len()-16))
end
-- load the udp.port table
udp_table = DissectorTable.get("udp.port")
-- register our protocol to handle udp port 60000
udp_table:add(60000,avn_roach_proto)

