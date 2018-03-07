//
//  IOCTL.h
//  QUICTester
//
//  Created by Quentin De Coninck on 1/19/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

#ifndef IOCTL_h
#define IOCTL_h

#import <sys/ioctl.h>
#import <sys/types.h>
#import <sys/sockio.h>
#import <sys/socket.h>
#import <unistd.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <netinet/in.h>
#import <net/ethernet.h>
#import <arpa/inet.h>
#import <netinet/tcp.h>

struct if_interface_state {
    /*
     * The bitmask tells which of the fields
     * to consider:
     * - When setting, to control which fields
     *   are being modified;
     * - When getting, it tells which fields are set.
     */
    u_int8_t valid_bitmask;
#define    IF_INTERFACE_STATE_RRC_STATE_VALID        0x1
#define    IF_INTERFACE_STATE_LQM_STATE_VALID        0x2
#define    IF_INTERFACE_STATE_INTERFACE_AVAILABILITY_VALID    0x4
    
    /*
     * Valid only for cellular interface
     */
    u_int8_t rrc_state;
#define    IF_INTERFACE_STATE_RRC_STATE_IDLE    0x0
#define    IF_INTERFACE_STATE_RRC_STATE_CONNECTED    0x1
    
    /*
     * Values normalized to the edge of the following values
     * that are defined on <net/if.h>:
     *  IFNET_LQM_THRESH_BAD
     *  IFNET_LQM_THRESH_POOR
     *  IFNET_LQM_THRESH_GOOD
     */
    int8_t lqm_state;
    
    /*
     * Indicate if the underlying link is currently
     * available
     */
    u_int8_t interface_availability;
#define    IF_INTERFACE_STATE_INTERFACE_AVAILABLE        0x0
#define    IF_INTERFACE_STATE_INTERFACE_UNAVAILABLE    0x1
};

/*
 * Interface request structure used for socket
 * ioctl's.  All interface ioctl's must have parameter
 * definitions which begin with ifr_name.  The
 * remainder may be interface specific.
 */
struct    ifreqfull {
#ifndef IFNAMSIZ
#define    IFNAMSIZ    IF_NAMESIZE
#endif
    char    ifr_name[IFNAMSIZ];        /* if name, e.g. "en0" */
    union {
        struct    sockaddr ifru_addr;
        struct    sockaddr ifru_dstaddr;
        struct    sockaddr ifru_broadaddr;
        short    ifru_flags;
        int    ifru_metric;
        int    ifru_mtu;
        int    ifru_phys;
        int    ifru_media;
        int    ifru_intval;
        caddr_t    ifru_data;
#ifdef KERNEL_PRIVATE
        u_int64_t ifru_data64;    /* 64-bit ifru_data */
#endif /* KERNEL_PRIVATE */
        struct    ifdevmtu ifru_devmtu;
        struct    ifkpi    ifru_kpi;
        u_int32_t ifru_wake_flags;
        u_int32_t ifru_route_refcnt;
        int    ifru_link_quality_metric;
        int    ifru_cap[2];
        struct {
            uint32_t    ifo_flags;
#define    IFRIFOF_BLOCK_OPPORTUNISTIC    0x00000001
            uint32_t    ifo_inuse;
        } ifru_opportunistic;
        u_int64_t ifru_eflags;
        struct {
            int32_t        ifl_level;
            uint32_t    ifl_flags;
#define    IFRLOGF_DLIL            0x00000001
#define    IFRLOGF_FAMILY            0x00010000
#define    IFRLOGF_DRIVER            0x01000000
#define    IFRLOGF_FIRMWARE        0x10000000
            int32_t        ifl_category;
#define    IFRLOGCAT_CONNECTIVITY        1
#define    IFRLOGCAT_QUALITY        2
#define    IFRLOGCAT_PERFORMANCE        3
            int32_t        ifl_subcategory;
        } ifru_log;
        u_int32_t ifru_delegated;
        struct {
            uint32_t    ift_type;
            uint32_t    ift_family;
#define    IFRTYPE_FAMILY_ANY        0
#define    IFRTYPE_FAMILY_LOOPBACK        1
#define    IFRTYPE_FAMILY_ETHERNET        2
#define    IFRTYPE_FAMILY_SLIP        3
#define    IFRTYPE_FAMILY_TUN        4
#define    IFRTYPE_FAMILY_VLAN        5
#define    IFRTYPE_FAMILY_PPP        6
#define    IFRTYPE_FAMILY_PVC        7
#define    IFRTYPE_FAMILY_DISC        8
#define    IFRTYPE_FAMILY_MDECAP        9
#define    IFRTYPE_FAMILY_GIF        10
#define    IFRTYPE_FAMILY_FAITH        11
#define    IFRTYPE_FAMILY_STF        12
#define    IFRTYPE_FAMILY_FIREWIRE        13
#define    IFRTYPE_FAMILY_BOND        14
#define    IFRTYPE_FAMILY_CELLULAR        15
            uint32_t    ift_subfamily;
#define    IFRTYPE_SUBFAMILY_ANY        0
#define    IFRTYPE_SUBFAMILY_USB        1
#define    IFRTYPE_SUBFAMILY_BLUETOOTH    2
#define    IFRTYPE_SUBFAMILY_WIFI        3
#define    IFRTYPE_SUBFAMILY_THUNDERBOLT    4
#define    IFRTYPE_SUBFAMILY_RESERVED    5
#define    IFRTYPE_SUBFAMILY_INTCOPROC    6
        } ifru_type;
        u_int32_t ifru_functional_type;
#define IFRTYPE_FUNCTIONAL_UNKNOWN    0
#define IFRTYPE_FUNCTIONAL_LOOPBACK    1
#define IFRTYPE_FUNCTIONAL_WIRED    2
#define IFRTYPE_FUNCTIONAL_WIFI_INFRA    3
#define IFRTYPE_FUNCTIONAL_WIFI_AWDL    4
#define IFRTYPE_FUNCTIONAL_CELLULAR    5
#define    IFRTYPE_FUNCTIONAL_INTCOPROC    6
#define IFRTYPE_FUNCTIONAL_LAST        6
        u_int32_t ifru_expensive;
        u_int32_t ifru_2kcl;
        struct {
            u_int32_t qlen;
            u_int32_t timeout;
        } ifru_start_delay;
        struct if_interface_state    ifru_interface_state;
        u_int32_t ifru_probe_connectivity;
        u_int32_t ifru_ecn_mode;
#define    IFRTYPE_ECN_DEFAULT        0
#define    IFRTYPE_ECN_ENABLE        1
#define    IFRTYPE_ECN_DISABLE        2
        u_int32_t ifru_qosmarking_mode;
#define    IFRTYPE_QOSMARKING_MODE_NONE        0
#define    IFRTYPE_QOSMARKING_FASTLANE    1
        u_int32_t ifru_qosmarking_enabled;
        u_int32_t ifru_disable_output;
        u_int32_t ifru_low_internet;
#define    IFRTYPE_LOW_INTERNET_DISABLE_UL_DL    0x0000
#define    IFRTYPE_LOW_INTERNET_ENABLE_UL        0x0001
#define    IFRTYPE_LOW_INTERNET_ENABLE_DL        0x0002
    } ifr_ifru;
#define    ifr_addr    ifr_ifru.ifru_addr    /* address */
#define    ifr_dstaddr    ifr_ifru.ifru_dstaddr    /* other end of p-to-p link */
#define    ifr_broadaddr    ifr_ifru.ifru_broadaddr    /* broadcast address */
#ifdef __APPLE__
#define    ifr_flags    ifr_ifru.ifru_flags    /* flags */
#else
#define    ifr_flags    ifr_ifru.ifru_flags[0]    /* flags */
#define    ifr_prevflags    ifr_ifru.ifru_flags[1]    /* flags */
#endif /* __APPLE__ */
#define    ifr_metric    ifr_ifru.ifru_metric    /* metric */
#define    ifr_mtu        ifr_ifru.ifru_mtu    /* mtu */
#define    ifr_phys    ifr_ifru.ifru_phys    /* physical wire */
#define    ifr_media    ifr_ifru.ifru_media    /* physical media */
#define    ifr_data    ifr_ifru.ifru_data    /* for use by interface */
#define    ifr_devmtu    ifr_ifru.ifru_devmtu
#define    ifr_intval    ifr_ifru.ifru_intval    /* integer value */
#ifdef KERNEL_PRIVATE
#define    ifr_data64    ifr_ifru.ifru_data64    /* 64-bit pointer */
#endif /* KERNEL_PRIVATE */
#define    ifr_kpi        ifr_ifru.ifru_kpi
#define    ifr_wake_flags    ifr_ifru.ifru_wake_flags /* wake capabilities */
#define    ifr_route_refcnt ifr_ifru.ifru_route_refcnt /* route references count */
#define    ifr_link_quality_metric ifr_ifru.ifru_link_quality_metric /* LQM */
#define    ifr_reqcap    ifr_ifru.ifru_cap[0]    /* requested capabilities */
#define    ifr_curcap    ifr_ifru.ifru_cap[1]    /* current capabilities */
#define    ifr_opportunistic    ifr_ifru.ifru_opportunistic
#define    ifr_eflags    ifr_ifru.ifru_eflags    /* extended flags  */
#define    ifr_log        ifr_ifru.ifru_log    /* logging level/flags */
#define    ifr_delegated    ifr_ifru.ifru_delegated /* delegated interface index */
#define    ifr_expensive    ifr_ifru.ifru_expensive
#define    ifr_type    ifr_ifru.ifru_type    /* interface type */
#define    ifr_functional_type    ifr_ifru.ifru_functional_type
#define    ifr_2kcl    ifr_ifru.ifru_2kcl
#define    ifr_start_delay_qlen    ifr_ifru.ifru_start_delay.qlen
#define    ifr_start_delay_timeout    ifr_ifru.ifru_start_delay.timeout
#define ifr_interface_state    ifr_ifru.ifru_interface_state
#define    ifr_probe_connectivity    ifr_ifru.ifru_probe_connectivity
#define    ifr_ecn_mode    ifr_ifru.ifru_ecn_mode
#define    ifr_qosmarking_mode    ifr_ifru.ifru_qosmarking_mode
#define    ifr_fastlane_capable    ifr_qosmarking_mode
#define ifr_qosmarking_enabled    ifr_ifru.ifru_qosmarking_enabled
#define    ifr_fastlane_enabled    ifr_qosmarking_enabled
#define    ifr_disable_output    ifr_ifru.ifru_disable_output
#define    ifr_low_internet    ifr_ifru.ifru_low_internet
};


#ifndef SIOCGIFLINKQUALITYMETRIC
#define SIOCGIFLINKQUALITYMETRIC _IOWR('i', 138, struct ifreq)
#define ifr_link_quality_metric ifr_ifru.ifru_link_quality_metric
#endif

#ifndef SIOCGASSOCIDS
struct so_aidreq {
    __uint32_t sar_cnt; /* number of associations */
    sae_associd_t *sar_aidp; /* array of assocations IDS */
};
#define SIOCGASSOCIDS _IOWR('s', 150, struct so_aidreq) /* get_associds */
#endif

#ifndef SIOCGCONNIDS
struct so_cidreq {
    sae_associd_t src_aid; /* association ID */
    __uint32_t scr_cnt; /* number of connections */
    sae_connid_t *scr_cidp; /* array of connections ID */
};
#define SIOCGCONNIDS _IOWR('s', 151, struct so_cidreq) /* get connids */
#endif

#ifndef SIOCGCONNINFO
/*
 * Structure for SIOCGCONNINFO
 */
struct so_cinforeq {
    sae_connid_t    scir_cid;        /* connection ID */
    __uint32_t    scir_flags;        /* see flags below */
    __uint32_t    scir_ifindex;        /* (last) outbound interface */
    __int32_t    scir_error;        /* most recent error */
    struct sockaddr    *scir_src;        /* source address */
    socklen_t    scir_src_len;        /* source address len */
    struct sockaddr *scir_dst;        /* destination address */
    socklen_t    scir_dst_len;        /* destination address len */
    __uint32_t    scir_aux_type;        /* aux data type (CIAUX) */
    void        *scir_aux_data;        /* aux data */
    __uint32_t    scir_aux_len;        /* aux data len */
};
#define SIOCGCONNINFO _IOWR('s', 152, struct so_cinforeq) /* get conninfo */
#endif

#ifndef TCP_INFO
#define TCP_INFO 0x200
/*
 * The TCP_INFO socket option is a private API and is subject to change
 */
#pragma pack(4)

#define    TCPI_OPT_TIMESTAMPS    0x01
#define    TCPI_OPT_SACK        0x02
#define    TCPI_OPT_WSCALE        0x04
#define    TCPI_OPT_ECN        0x08

#define TCPI_FLAG_LOSSRECOVERY    0x01    /* Currently in loss recovery */
#define    TCPI_FLAG_STREAMING_ON    0x02    /* Streaming detection on */

struct tcp_conn_status {
    unsigned int    probe_activated : 1;
    unsigned int    write_probe_failed : 1;
    unsigned int    read_probe_failed : 1;
    unsigned int    conn_probe_failed : 1;
};

/*
 * Add new fields to this structure at the end only. This will preserve
 * binary compatibility.
 */
struct tcp_info {
    u_int8_t    tcpi_state;            /* TCP FSM state. */
    u_int8_t    tcpi_options;        /* Options enabled on conn. */
    u_int8_t    tcpi_snd_wscale;    /* RFC1323 send shift value. */
    u_int8_t    tcpi_rcv_wscale;    /* RFC1323 recv shift value. */
    
    u_int32_t    tcpi_flags;            /* extra flags (TCPI_FLAG_xxx) */
    
    u_int32_t    tcpi_rto;            /* Retransmission timeout in milliseconds */
    u_int32_t    tcpi_snd_mss;        /* Max segment size for send. */
    u_int32_t    tcpi_rcv_mss;        /* Max segment size for receive. */
    
    u_int32_t    tcpi_rttcur;        /* Most recent value of RTT */
    u_int32_t    tcpi_srtt;            /* Smoothed RTT */
    u_int32_t    tcpi_rttvar;        /* RTT variance */
    u_int32_t    tcpi_rttbest;        /* Best RTT we've seen */
    
    u_int32_t    tcpi_snd_ssthresh;    /* Slow start threshold. */
    u_int32_t    tcpi_snd_cwnd;        /* Send congestion window. */
    
    u_int32_t    tcpi_rcv_space;        /* Advertised recv window. */
    
    u_int32_t    tcpi_snd_wnd;        /* Advertised send window. */
    u_int32_t    tcpi_snd_nxt;        /* Next egress seqno */
    u_int32_t    tcpi_rcv_nxt;        /* Next ingress seqno */
    
    int32_t        tcpi_last_outif;    /* if_index of interface used to send last */
    u_int32_t    tcpi_snd_sbbytes;    /* bytes in snd buffer including data inflight */
    
    u_int64_t    tcpi_txpackets __attribute__((aligned(8)));    /* total packets sent */
    u_int64_t    tcpi_txbytes __attribute__((aligned(8)));
    /* total bytes sent */
    u_int64_t    tcpi_txretransmitbytes __attribute__((aligned(8)));
    /* total bytes retransmitted */
    u_int64_t    tcpi_txunacked __attribute__((aligned(8)));
    /* current number of bytes not acknowledged */
    u_int64_t    tcpi_rxpackets __attribute__((aligned(8)));    /* total packets received */
    u_int64_t    tcpi_rxbytes __attribute__((aligned(8)));
    /* total bytes received */
    u_int64_t    tcpi_rxduplicatebytes __attribute__((aligned(8)));
    /* total duplicate bytes received */
    u_int64_t    tcpi_rxoutoforderbytes __attribute__((aligned(8)));
    /* total out of order bytes received */
    u_int64_t    tcpi_snd_bw __attribute__((aligned(8)));    /* measured send bandwidth in bits/sec */
    u_int8_t    tcpi_synrexmits;    /* Number of syn retransmits before connect */
    u_int8_t    tcpi_unused1;
    u_int16_t    tcpi_unused2;
    u_int64_t    tcpi_cell_rxpackets __attribute((aligned(8)));    /* packets received over cellular */
    u_int64_t    tcpi_cell_rxbytes __attribute((aligned(8)));    /* bytes received over cellular */
    u_int64_t    tcpi_cell_txpackets __attribute((aligned(8)));    /* packets transmitted over cellular */
    u_int64_t    tcpi_cell_txbytes __attribute((aligned(8)));    /* bytes transmitted over cellular */
    u_int64_t    tcpi_wifi_rxpackets __attribute((aligned(8)));    /* packets received over Wi-Fi */
    u_int64_t    tcpi_wifi_rxbytes __attribute((aligned(8)));    /* bytes received over Wi-Fi */
    u_int64_t    tcpi_wifi_txpackets __attribute((aligned(8)));    /* packets transmitted over Wi-Fi */
    u_int64_t    tcpi_wifi_txbytes __attribute((aligned(8)));    /* bytes transmitted over Wi-Fi */
    u_int64_t    tcpi_wired_rxpackets __attribute((aligned(8)));    /* packets received over Wired */
    u_int64_t    tcpi_wired_rxbytes __attribute((aligned(8)));    /* bytes received over Wired */
    u_int64_t    tcpi_wired_txpackets __attribute((aligned(8)));    /* packets transmitted over Wired */
    u_int64_t    tcpi_wired_txbytes __attribute((aligned(8)));    /* bytes transmitted over Wired */
    struct tcp_conn_status    tcpi_connstatus; /* status of connection probes */
    
    u_int16_t
tcpi_tfo_cookie_req:1, /* Cookie requested? */
tcpi_tfo_cookie_rcv:1, /* Cookie received? */
tcpi_tfo_syn_loss:1,   /* Fallback to reg. TCP after SYN-loss */
tcpi_tfo_syn_data_sent:1, /* SYN+data has been sent out */
tcpi_tfo_syn_data_acked:1, /* SYN+data has been fully acknowledged */
tcpi_tfo_syn_data_rcv:1, /* Server received SYN+data with a valid cookie */
tcpi_tfo_cookie_req_rcv:1, /* Server received cookie-request */
tcpi_tfo_cookie_sent:1, /* Server announced cookie */
tcpi_tfo_cookie_invalid:1, /* Server received an invalid cookie */
tcpi_tfo_cookie_wrong:1, /* Our sent cookie was wrong */
tcpi_tfo_no_cookie_rcv:1, /* We did not receive a cookie upon our request */
tcpi_tfo_heuristics_disable:1, /* TFO-heuristics disabled it */
tcpi_tfo_send_blackhole:1, /* A sending-blackhole got detected */
tcpi_tfo_recv_blackhole:1, /* A receiver-blackhole got detected */
tcpi_tfo_onebyte_proxy:1; /* A proxy acknowledges all but one byte of the SYN */
    
    u_int16_t    tcpi_ecn_client_setup:1,    /* Attempted ECN setup from client side */
tcpi_ecn_server_setup:1,    /* Attempted ECN setup from server side */
tcpi_ecn_success:1,        /* peer negotiated ECN */
tcpi_ecn_lost_syn:1,        /* Lost SYN with ECN setup */
tcpi_ecn_lost_synack:1,        /* Lost SYN-ACK with ECN setup */
tcpi_local_peer:1,        /* Local to the host or the subnet */
tcpi_if_cell:1,        /* Interface is cellular */
tcpi_if_wifi:1,        /* Interface is WiFi */
tcpi_if_wired:1,    /* Interface is wired - ethernet , thunderbolt etc,. */
tcpi_if_wifi_infra:1,    /* Interface is wifi infrastructure */
tcpi_if_wifi_awdl:1,    /* Interface is wifi AWDL */
tcpi_snd_background:1,    /* Using delay based algorithm on sender side */
tcpi_rcv_background:1;    /* Using delay based algorithm on receive side */
    
    u_int32_t    tcpi_ecn_recv_ce;    /* Packets received with CE */
    u_int32_t    tcpi_ecn_recv_cwr;    /* Packets received with CWR */
    
    u_int32_t    tcpi_rcvoopack;        /* out-of-order packets received */
    u_int32_t    tcpi_pawsdrop;        /* segments dropped due to PAWS */
    u_int32_t    tcpi_sack_recovery_episode; /* SACK recovery episodes */
    u_int32_t    tcpi_reordered_pkts;    /* packets reorderd */
    u_int32_t    tcpi_dsack_sent;    /* Sent DSACK notification */
    u_int32_t    tcpi_dsack_recvd;    /* Received a valid DSACK option */
    u_int32_t    tcpi_flowhash;        /* Unique id for the connection */
    
    u_int64_t    tcpi_txretransmitpackets __attribute__((aligned(8)));
};

struct tcp_measure_bw_burst {
    u_int32_t    min_burst_size; /* Minimum number of packets to use */
    u_int32_t    max_burst_size; /* Maximum number of packets to use */
};

/*
 * Note that IPv6 link local addresses should have the appropriate scope ID
 */

struct info_tuple {
    u_int8_t    itpl_proto;
    union {
        struct sockaddr        _itpl_sa;
        struct sockaddr_in    _itpl_sin;
        struct sockaddr_in6    _itpl_sin6;
    } itpl_localaddr;
    union {
        struct sockaddr        _itpl_sa;
        struct sockaddr_in    _itpl_sin;
        struct sockaddr_in6    _itpl_sin6;
    } itpl_remoteaddr;
};

#define itpl_local_sa        itpl_localaddr._itpl_sa
#define itpl_local_sin        itpl_localaddr._itpl_sin
#define itpl_local_sin6        itpl_localaddr._itpl_sin6
#define itpl_remote_sa        itpl_remoteaddr._itpl_sa
#define itpl_remote_sin        itpl_remoteaddr._itpl_sin
#define itpl_remote_sin6    itpl_remoteaddr._itpl_sin6

/*
 * TCP connection info auxiliary data (CIAUX_TCP)
 *
 * Do not add new fields to this structure, just add them to tcp_info
 * structure towards the end. This will preserve binary compatibility.
 */
typedef struct conninfo_tcp {
    pid_t            tcpci_peer_pid;    /* loopback peer PID if > 0 */
    struct tcp_info        tcpci_tcp_info;    /* TCP info */
} conninfo_tcp_t;

#pragma pack()

struct mptcp_itf_stats {
    uint16_t    ifindex;
    uint16_t    switches;
    uint32_t    is_expensive:1;
    uint64_t    mpis_txbytes __attribute__((aligned(8)));
    uint64_t    mpis_rxbytes __attribute__((aligned(8)));
};

/* Version solely used to let libnetcore survive */
#define    CONNINFO_MPTCP_VERSION    3
typedef struct conninfo_multipathtcp {
    uint32_t    mptcpci_subflow_count;
    uint32_t    mptcpci_switch_count;
    sae_connid_t    mptcpci_subflow_connids[4];
    
    uint64_t    mptcpci_init_rxbytes;
    uint64_t    mptcpci_init_txbytes;
    
#define    MPTCP_ITFSTATS_SIZE    4
    struct mptcp_itf_stats mptcpci_itfstats[MPTCP_ITFSTATS_SIZE];
    
    uint32_t    mptcpci_flags;
#define    MPTCPCI_FIRSTPARTY    0x01
} conninfo_multipathtcp_t;
#endif

@interface IOCTL : NSObject

+ (NSMutableDictionary *)getMPTCPInfo:(int)fd;
@end

#endif /* IOCTL_h */
