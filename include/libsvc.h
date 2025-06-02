
#if !defined(_LIBSVC_H)
#define _LIBSVC_H

#include <stdint.h>

#define LIBSVC_ERROR_NONE   0

struct svc_t
{
    int (*channel_pdu)(struct svc_t* svc, uint16_t channel_id,
                       void* data, uint32_t bytes);
    void* user;
};

struct svc_channels_t
{
    int (*log_msg)(struct svc_channels_t* svc, const char* msg);
    int (*channel_pdu)(struct svc_channels_t* svc, uint16_t channel_id,
                       uint32_t total_bytes, uint32_t flags,
                       void* data, uint32_t bytes);
    struct svc_t channels[16];
    void* user;
};

int svc_init(void);
int svc_deinit(void);
int svc_create(struct svc_channels_t** svc_channels);
int svc_delete(struct svc_channels_t* svc_channels);
/* data from server to client, may call channel_pdu above */
int svc_process_data(struct svc_channels_t* svc_channels,
                     uint16_t channel_id,
                     void* data, uint32_t bytes);
int svc_send_data(struct svc_channels_t* svc_channels,
                  uint16_t channel_id,
                  void* data, uint32_t bytes);
   
#endif
