//
//  TCPInfoConverter.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 10/24/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

func tcpInfoToDict(tcpi: tcp_connection_info) -> [String: Any] {
    return [
        "tcpi_state": tcpi.tcpi_state,
        "tcpi_snd_wscale": tcpi.tcpi_snd_wscale,
        "tcpi_rcv_wscale": tcpi.tcpi_rcv_wscale,
        "tcpi_options": tcpi.tcpi_options,
        "tcpi_flags": tcpi.tcpi_flags,
        "tcpi_rto": tcpi.tcpi_rto,
        "tcpi_maxseg": tcpi.tcpi_maxseg,
        "tcpi_snd_ssthresh": tcpi.tcpi_snd_ssthresh,
        "tcpi_snd_cwnd": tcpi.tcpi_snd_cwnd,
        "tcpi_snd_wnd": tcpi.tcpi_snd_wnd,
        "tcpi_snd_sbbytes": tcpi.tcpi_snd_sbbytes,
        "tcpi_rcv_wnd": tcpi.tcpi_rcv_wnd,
        "tcpi_rttcur": tcpi.tcpi_rttcur,
        "tcpi_srtt": tcpi.tcpi_srtt,
        "tcpi_rttvar": tcpi.tcpi_rttvar,
        "tcpi_txpackets": tcpi.tcpi_txpackets,
        "tcpi_txbytes": tcpi.tcpi_txbytes,
        "tcpi_txretransmitbytes": tcpi.tcpi_txretransmitbytes,
        "tcpi_rxpackets": tcpi.tcpi_rxpackets,
        "tcpi_rxbytes": tcpi.tcpi_rxbytes,
        "tcpi_rxoutoforderbytes": tcpi.tcpi_rxoutoforderbytes,
        "tcpi_txretransmitpackets": tcpi.tcpi_txretransmitpackets,
    ]
}
