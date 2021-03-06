# TCL File Generated by Component Editor 12.1
# Mon Apr 08 15:40:55 BST 2013
# DO NOT MODIFY


# 
# CHERI "CHERI" v1.0
# null 2013.04.08.15:40:55
# 
# 

# 
# request TCL package from ACDS 12.1
# 
package require -exact qsys 12.1

# 
# module CHERI
# 
set ip_subdir [lindex [split [pwd] '/'] end]
set has_trace [string match *_trace* $ip_subdir]
set_module_property NAME [string toupper $ip_subdir]
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP BERI_Processors
set_module_property DISPLAY_NAME CHERI_FPU
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL mkTopAvalonPhy
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set verilog_files [glob -tails *.v]
foreach file $verilog_files {
	add_fileset_file $file VERILOG PATH $file
}
foreach file [glob -tails *.hex] {
    add_fileset_file $file HEX PATH $file
}

# 
# parameters
# 


# 
# display items
# 


# 
# connection point clockreset
# 
add_interface clockreset clock end
set_interface_property clockreset clockRate 0
set_interface_property clockreset ENABLED true

add_interface_port clockreset csi_clockreset_clk clk Input 1


# 
# connection point clockreset_reset
# 
add_interface clockreset_reset reset end
set_interface_property clockreset_reset associatedClock clockreset
set_interface_property clockreset_reset synchronousEdges DEASSERT
set_interface_property clockreset_reset ENABLED true

add_interface_port clockreset_reset csi_clockreset_reset_n reset_n Input 1


# 
# connection point reset_source
# 
add_interface reset_source reset start
set_interface_property reset_source associatedClock clockreset
set_interface_property reset_source associatedDirectReset ""
set_interface_property reset_source associatedResetSinks ""
set_interface_property reset_source synchronousEdges NONE
set_interface_property reset_source ENABLED true

add_interface_port reset_source avm_reset_n_out reset_n Output 1


# 
# connection point avalon_master_0
# 
add_interface avalon_master_0 avalon start
set_interface_property avalon_master_0 addressUnits SYMBOLS
set_interface_property avalon_master_0 associatedClock clockreset
set_interface_property avalon_master_0 associatedReset clockreset_reset
set_interface_property avalon_master_0 bitsPerSymbol 8
set_interface_property avalon_master_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_master_0 burstcountUnits WORDS
set_interface_property avalon_master_0 doStreamReads false
set_interface_property avalon_master_0 doStreamWrites false
set_interface_property avalon_master_0 holdTime 0
set_interface_property avalon_master_0 linewrapBursts false
set_interface_property avalon_master_0 maximumPendingReadTransactions 0
set_interface_property avalon_master_0 readLatency 0
set_interface_property avalon_master_0 readWaitTime 1
set_interface_property avalon_master_0 setupTime 0
set_interface_property avalon_master_0 timingUnits Cycles
set_interface_property avalon_master_0 writeWaitTime 0
set_interface_property avalon_master_0 ENABLED true

add_interface_port avalon_master_0 avm_readdata readdata Input 256
add_interface_port avalon_master_0 avm_readdatavalid readdatavalid Input 1
add_interface_port avalon_master_0 avm_waitrequest waitrequest Input 1
add_interface_port avalon_master_0 avm_writedata writedata Output 256
add_interface_port avalon_master_0 avm_read read Output 1
add_interface_port avalon_master_0 avm_write write Output 1
add_interface_port avalon_master_0 avm_byteenable byteenable Output 32
add_interface_port avalon_master_0 avm_address address Output 40


# 
# connection point irq
# 
add_interface irq interrupt start
set_interface_property irq associatedAddressablePoint avalon_master_0
set_interface_property irq associatedClock clockreset
set_interface_property irq associatedReset clockreset_reset
set_interface_property irq irqScheme INDIVIDUAL_REQUESTS
set_interface_property irq ENABLED true

add_interface_port irq avm_irq_irqs irq Input 32


# 
# connection point avalon_streaming_sink
# 
add_interface avalon_streaming_sink avalon_streaming end
set_interface_property avalon_streaming_sink associatedClock clockreset
set_interface_property avalon_streaming_sink associatedReset clockreset_reset
set_interface_property avalon_streaming_sink dataBitsPerSymbol 8
set_interface_property avalon_streaming_sink errorDescriptor ""
set_interface_property avalon_streaming_sink firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_sink maxChannel 0
set_interface_property avalon_streaming_sink readyLatency 0
set_interface_property avalon_streaming_sink ENABLED true

add_interface_port avalon_streaming_sink debugStreamSink_stream_in_data data Input 8
add_interface_port avalon_streaming_sink debugStreamSink_stream_in_valid valid Input 1
add_interface_port avalon_streaming_sink debugStreamSink_stream_in_ready ready Output 1


# 
# connection point avalon_streaming_source
# 
add_interface avalon_streaming_source avalon_streaming start
set_interface_property avalon_streaming_source associatedClock clockreset
set_interface_property avalon_streaming_source associatedReset clockreset_reset
set_interface_property avalon_streaming_source dataBitsPerSymbol 8
set_interface_property avalon_streaming_source errorDescriptor ""
set_interface_property avalon_streaming_source firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_source maxChannel 0
set_interface_property avalon_streaming_source readyLatency 0
set_interface_property avalon_streaming_source ENABLED true

add_interface_port avalon_streaming_source debugStreamSource_stream_out_data data Output 8
add_interface_port avalon_streaming_source debugStreamSource_stream_out_valid valid Output 1
add_interface_port avalon_streaming_source debugStreamSource_stream_out_ready ready Input 1

if $has_trace {
    # 
    # connection point debug_m0
    # 
    add_interface debug_m0 avalon start
    set_interface_property debug_m0 addressUnits SYMBOLS
    set_interface_property debug_m0 associatedClock clockreset
    set_interface_property debug_m0 associatedReset clockreset_reset
    set_interface_property debug_m0 bitsPerSymbol 8
    set_interface_property debug_m0 burstOnBurstBoundariesOnly false
    set_interface_property debug_m0 burstcountUnits WORDS
    set_interface_property debug_m0 doStreamReads false
    set_interface_property debug_m0 doStreamWrites false
    set_interface_property debug_m0 holdTime 0
    set_interface_property debug_m0 linewrapBursts false
    set_interface_property debug_m0 maximumPendingReadTransactions 0
    set_interface_property debug_m0 readLatency 0
    set_interface_property debug_m0 readWaitTime 1
    set_interface_property debug_m0 setupTime 0
    set_interface_property debug_m0 timingUnits Cycles
    set_interface_property debug_m0 writeWaitTime 0
    set_interface_property debug_m0 ENABLED true
    set_interface_property debug_m0 EXPORT_OF ""
    set_interface_property debug_m0 PORT_NAME_MAP ""
    set_interface_property debug_m0 SVD_ADDRESS_GROUP ""

    add_interface_port debug_m0 avm_debug_m0_readdatavalid readdatavalid Input 1
    add_interface_port debug_m0 avm_debug_m0_waitrequest waitrequest Input 1
    add_interface_port debug_m0 avm_debug_m0_writedata writedata Output 256
    add_interface_port debug_m0 avm_debug_m0_address address Output 30
    add_interface_port debug_m0 avm_debug_m0_read read Output 1
    add_interface_port debug_m0 avm_debug_m0_write write Output 1
    add_interface_port debug_m0 avm_debug_m0_burstcount burstcount Output 4
    add_interface_port debug_m0 avm_debug_m0_readdata readdata Input 256
}

# 
# connection point compositor_m0
# 
add_interface compositor_m0 avalon start
set_interface_property compositor_m0 addressUnits SYMBOLS
set_interface_property compositor_m0 associatedClock clockreset
set_interface_property compositor_m0 associatedReset clockreset_reset
set_interface_property compositor_m0 bitsPerSymbol 8
set_interface_property compositor_m0 burstOnBurstBoundariesOnly false
set_interface_property compositor_m0 burstcountUnits WORDS
set_interface_property compositor_m0 doStreamReads false
set_interface_property compositor_m0 doStreamWrites false
set_interface_property compositor_m0 holdTime 0
set_interface_property compositor_m0 linewrapBursts false
set_interface_property compositor_m0 maximumPendingReadTransactions 0
set_interface_property compositor_m0 readLatency 0
set_interface_property compositor_m0 readWaitTime 1
set_interface_property compositor_m0 setupTime 0
set_interface_property compositor_m0 timingUnits Cycles
set_interface_property compositor_m0 writeWaitTime 0
set_interface_property compositor_m0 ENABLED true

add_interface_port compositor_m0 avm_compositor_m0_readdata readdata Input 256
add_interface_port compositor_m0 avm_compositor_m0_readdatavalid readdatavalid Input 1
add_interface_port compositor_m0 avm_compositor_m0_waitrequest waitrequest Input 1
add_interface_port compositor_m0 avm_compositor_m0_writedata writedata Output 256
add_interface_port compositor_m0 avm_compositor_m0_address address Output 32
add_interface_port compositor_m0 avm_compositor_m0_read read Output 1
add_interface_port compositor_m0 avm_compositor_m0_write write Output 1
add_interface_port compositor_m0 avm_compositor_m0_burstcount burstcount Output 4


# 
# connection point compositorpixelsout_stream_out
# 
add_interface compositorpixelsout_stream_out avalon_streaming start
set_interface_property compositorpixelsout_stream_out associatedClock clockreset
set_interface_property compositorpixelsout_stream_out associatedReset clockreset_reset
set_interface_property compositorpixelsout_stream_out dataBitsPerSymbol 24
set_interface_property compositorpixelsout_stream_out errorDescriptor ""
set_interface_property compositorpixelsout_stream_out firstSymbolInHighOrderBits true
set_interface_property compositorpixelsout_stream_out maxChannel 0
set_interface_property compositorpixelsout_stream_out readyLatency 0
set_interface_property compositorpixelsout_stream_out ENABLED true

add_interface_port compositorpixelsout_stream_out compositorPixelsOut_stream_out_endofpacket endofpacket Output 1
add_interface_port compositorpixelsout_stream_out compositorPixelsOut_stream_out_startofpacket startofpacket Output 1
add_interface_port compositorpixelsout_stream_out compositorPixelsOut_stream_out_ready ready Input 1
add_interface_port compositorpixelsout_stream_out compositorPixelsOut_stream_out_valid valid Output 1
add_interface_port compositorpixelsout_stream_out compositorPixelsOut_stream_out_data data Output 24


# 
# connection point compositor
# 
add_interface compositor clock end
set_interface_property compositor clockRate 0
set_interface_property compositor ENABLED true

add_interface_port compositor csi_compositor_clk clk Input 1


# 
# connection point compositor_reset
# 
add_interface compositor_reset reset end
set_interface_property compositor_reset associatedClock clockreset
set_interface_property compositor_reset synchronousEdges DEASSERT
set_interface_property compositor_reset ENABLED true

add_interface_port compositor_reset csi_compositor_reset_n reset_n Input 1
