import FIFOF::*;
import SpecialFIFOs::*;

import ClientServer::*;
import GetPut::*;
import Connectable::*;

module [Module] mkBufferOutputServer
    #(Module#(Server#(reqType, resType)) mkServer, Integer bufferLength)
    (Server#(reqType, resType))
    provisos (Bits#(resType, _));

    FIFOF#(resType) buffer <- mkSizedBypassFIFOF(bufferLength);
    Server#(reqType, resType) server <- mkServer();

    mkConnection(server.response, toPut(buffer));

    interface Put request = server.request;
    interface Get response = toGet(buffer);
endmodule
