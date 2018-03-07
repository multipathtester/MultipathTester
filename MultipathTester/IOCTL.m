//
//  IOCTL.m
//  QUICTester
//
//  Created by Quentin De Coninck on 1/19/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOCTL.h"

@implementation IOCTL

struct sockaddr_in srcv4;
struct sockaddr_in dstv4;
struct sockaddr_in6 srcv6;
struct sockaddr_in6 dstv6;
struct conninfo_tcp tcpi;
struct conninfo_multipathtcp cim;

+(void)getIPStr:(struct sockaddr *)addr :(NSMutableDictionary *)dict :(NSString *)key {
    switch(addr->sa_family) {
        case AF_INET: {
            struct sockaddr_in *addr_in = (struct sockaddr_in *)addr;
            char *s = malloc(INET_ADDRSTRLEN);
            if (s != nil) {
                inet_ntop(AF_INET, &(addr_in->sin_addr), s, INET_ADDRSTRLEN);
                [dict setObject: [NSString stringWithUTF8String:s] forKey:key];
                free(s);
            }
            break;
        }
        case AF_INET6: {
            struct sockaddr_in6 *addr_in6 = (struct sockaddr_in6 *)addr;
            char *s = malloc(INET6_ADDRSTRLEN);
            if (s != nil) {
                inet_ntop(AF_INET6, &(addr_in6->sin6_addr), s, INET6_ADDRSTRLEN);
                [dict setObject: [NSString stringWithUTF8String:s] forKey:key];
                free(s);
            }
            break;
        }
        default:
            break;
    }
}

+(NSMutableDictionary *)getMPTCPSfInfo:(int)fd :(sae_connid_t)cid :(NSMutableDictionary *)dict {
    struct so_cinforeq *creqsf = malloc(sizeof(struct so_cinforeq));
    if (creqsf == nil) {
        printf("First malloc\n");
        return nil;
    }
    
    // We need two iotcls: one to get the size of the IP addresses, the other to fetch the info
    creqsf->scir_aux_data = &tcpi;
    creqsf->scir_cid = cid;
    creqsf->scir_aux_len = 0; // Don't take info now
    creqsf->scir_src_len = 0; // What is the version of source IP?
    creqsf->scir_dst_len = 0; // What is the version of destination IP?
    
    const int l = ioctl(fd, SIOCGCONNINFO, creqsf);
    const int errnum1 = errno;
    if (l < 0) {
        perror("ioctl 1 try");
        printf("I went here: %d\n", errnum1);
        free(creqsf);
        return nil;
    }
    
    // What is the version of IP?
    if (creqsf->scir_src_len == sizeof(struct sockaddr_in)) {
        creqsf->scir_src = (struct sockaddr *)&srcv4;
    } else if (creqsf->scir_src_len == sizeof(struct sockaddr_in6)) {
        creqsf->scir_src = (struct sockaddr *)&srcv6;
    } else {
        printf("Unknown size for source IP: %d\n", creqsf->scir_src_len);
        return nil;
    }
    
    if (creqsf->scir_dst_len == sizeof(struct sockaddr_in)) {
        creqsf->scir_dst = (struct sockaddr *)&dstv4;
    } else if (creqsf->scir_dst_len == sizeof(struct sockaddr_in6)) {
        creqsf->scir_dst = (struct sockaddr *)&dstv6;
    } else {
        printf("Unknown size for destination IP: %d\n", creqsf->scir_dst_len);
        return nil;
    }
    
    creqsf->scir_aux_len = sizeof(struct conninfo_tcp); // Yip, otherwise it won't work :-)
    creqsf->scir_aux_data = &tcpi;
    creqsf->scir_cid = cid;
    
    const int k = ioctl(fd, SIOCGCONNINFO, creqsf);
    const int errnum = errno;
    if (k < 0) {
        perror("ioctl try");
        printf("I went here: %d\n", errnum);
        printf("Now len is %d\n", creqsf->scir_aux_len);
        free(creqsf);
        return nil;
    }

    [self getIPStr:creqsf->scir_src :dict :@"src_ip"];
    [self getIPStr:creqsf->scir_dst :dict :@"dst_ip"];
    struct tcp_info tcpinfo = tcpi.tcpci_tcp_info;
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_state] forKey: @"tcpi_state"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_options] forKey: @"tcpi_options"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_snd_wscale] forKey: @"tcpi_snd_wscale"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rcv_wscale] forKey: @"tcpi_rcv_wscale"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_flags] forKey: @"tcpi_flags"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rto] forKey: @"tcpi_rto"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_snd_mss] forKey: @"tcpi_snd_mss"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rcv_mss] forKey: @"tcpi_rcv_mss"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rttcur] forKey: @"tcpi_rttcur"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_srtt] forKey: @"tcpi_srtt"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rttvar] forKey: @"tcpi_rttvar"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rttbest] forKey: @"tcpi_rttbest"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_snd_ssthresh] forKey: @"tcpi_snd_ssthresh"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_snd_cwnd] forKey: @"tcpi_snd_cwnd"];
    
    [dict setObject: [NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rcv_space] forKey: @"tcpi_rcv_space"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_snd_wnd] forKey: @"tcpi_snd_wnd"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_snd_nxt] forKey: @"tcpi_snd_nxt"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rcv_nxt] forKey: @"tcpi_rcv_nxt"];
    
    [dict setObject:[NSNumber numberWithInteger: tcpinfo.tcpi_last_outif] forKey: @"tcp_last_outif"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_snd_sbbytes] forKey: @"tcpi_snd_sbbytes"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_txpackets] forKey: @"tcpi_txpackets"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_txbytes] forKey: @"tcpi_txbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_txretransmitbytes] forKey: @"tcpi_txretransmitbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_txunacked] forKey: @"tcpi_txunacked"];

    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rxpackets] forKey: @"tcpi_rxpackets"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rxbytes] forKey: @"tcpi_rxbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rxduplicatebytes] forKey: @"tcpi_rxduplicatebytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_rxoutoforderbytes] forKey: @"tcpi_rxoutoforderbytes"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_snd_bw] forKey: @"tcpi_snd_bw"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_synrexmits] forKey: @"tcpi_synrexmits"];
    
    // This seems duplicate with the fields after; collect them anyway?
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_cell_rxbytes] forKey: @"tcpi_cell_rxbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_cell_txbytes] forKey: @"tcpi_cell_txbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_cell_rxpackets] forKey: @"tcpi_cell_rxpackets"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_cell_txpackets] forKey: @"tcpi_cell_txpackets"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_wifi_rxbytes] forKey: @"tcpi_wifi_rxbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_wifi_txbytes] forKey: @"tcpi_wifi_txbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_wifi_rxpackets] forKey: @"tcpi_wifi_rxpackets"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_wifi_txpackets] forKey: @"tcpi_wifi_txpackets"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_wired_rxbytes] forKey: @"tcpi_wired_rxbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_wired_txbytes] forKey: @"tcpi_wired_txbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_wired_rxpackets] forKey: @"tcpi_wired_rxpackets"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_wired_txpackets] forKey: @"tcpi_wired_txpackets"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_if_cell] forKey: @"tcpi_if_cell"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_if_wifi] forKey: @"tcpi_if_wifi"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_if_wired] forKey: @"tcpi_if_wired"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_if_wifi_awdl] forKey: @"tcpi_if_wifi_awdl"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_if_wifi_infra] forKey: @"tcpi_if_wifi_infra"];
    
    [dict setObject:[NSNumber numberWithUnsignedInteger: tcpinfo.tcpi_txretransmitpackets] forKey: @"tcpi_txretransmitpackets"];

    free(creqsf);
    return dict;
}

+(NSMutableDictionary *)getMPTCPInfo:(int)fd {
    struct so_cinforeq *creq = malloc(sizeof(struct so_cinforeq));
    if (creq == nil) {
        printf("First malloc\n");
        return nil;
    }
    
    creq->scir_aux_len = 0; // Yip, otherwise it won't work :-)
    creq->scir_aux_data = &cim;
    creq->scir_cid = SAE_CONNID_ALL;
    const int i = ioctl(fd, SIOCGCONNINFO, creq);
    const int errnum = errno;
    if (i < 0) {
        perror("iotcl");
        NSLog(@"%d %d %d", i, errnum, EINVAL);
        free(creq);
        return nil;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:[NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]] forKey: @"time"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: cim.mptcpci_subflow_count] forKey: @"subflowcount"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: cim.mptcpci_init_txbytes] forKey: @"txbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: cim.mptcpci_init_rxbytes] forKey: @"rxbytes"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: cim.mptcpci_flags] forKey: @"flags"];
    [dict setObject:[NSNumber numberWithUnsignedInteger: cim.mptcpci_switch_count] forKey: @"switchcount"];

    NSMutableDictionary *sfs = [NSMutableDictionary new];
    for (int j = 0; j < cim.mptcpci_subflow_count; j++) {
        sae_connid_t scid = cim.mptcpci_subflow_connids[j];
        NSMutableDictionary *sf = [NSMutableDictionary new];
        struct mptcp_itf_stats stat = cim.mptcpci_itfstats[j];
        
        [sf setObject:[NSNumber numberWithUnsignedInteger: stat.ifindex] forKey: @"interfaceindex"];
        [sf setObject:[NSNumber numberWithUnsignedInteger: stat.is_expensive] forKey: @"isexpensive"];
        [sf setObject:[NSNumber numberWithUnsignedInteger: stat.mpis_rxbytes] forKey: @"rxbytes"];
        [sf setObject:[NSNumber numberWithUnsignedInteger: stat.mpis_txbytes] forKey: @"txbytes"];
        [sf setObject:[NSNumber numberWithUnsignedInteger: stat.switches] forKey: @"switches"];
        
        [self getMPTCPSfInfo:fd :scid :sf];

        [sfs setObject:sf forKey: [NSString stringWithFormat:@"%d", j]];
    }
    [dict setObject:sfs forKey:@"subflows"];

    free(creq);
    return dict;
}
@end
