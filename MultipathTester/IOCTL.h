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

@interface IOCTL : NSObject

+ (void)test;
+ (void)test2;
+ (void)getMPTCPInfo:(int)fd;
+ (NSMutableDictionary *)getMPTCPInfoClean:(int)fd;
@end

#endif /* IOCTL_h */
