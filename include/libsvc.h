
#if !defined(_LIBSVC_H)
#define _LIBSVC_H

#include <stdint.h>

#define LIBSVC_ERROR_NONE           0
#define LIBSVC_ERROR_CHANID         -1
#define LIBSVC_ERROR_MEMORY         -2
#define LIBSVC_ERROR_SEND_DATA      -3
#define LIBSVC_ERROR_PROCESS_DATA   -4
#define LIBSVC_ERROR_NO_CALLBACK    -5
#define LIBSVC_ERROR_LOG            -6

struct svc_t
{
    int (*process_data)(struct svc_t* svc, uint16_t channel_id,
                        void* data, uint32_t bytes);
    void* user;
};

struct svc_channels_t
{
    int (*log_msg)(struct svc_channels_t* svc, const char* msg);
    int (*send_data)(struct svc_channels_t* svc, uint16_t channel_id,
                     uint32_t total_bytes, uint32_t flags,
                     void* data, uint32_t bytes);
    struct svc_t channels[16];
    void* user;
};

int svc_init(void);
int svc_deinit(void);
int svc_create(struct svc_channels_t** svc_channels);
int svc_delete(struct svc_channels_t* svc_channels);
/* data from server to client, may call svc_t::process_data above */
int svc_process_data(struct svc_channels_t* svc_channels,
                     uint16_t channel_id,
                     void* data, uint32_t bytes);
/* data from client to server, should call svc_channels_t::send_data */
int svc_send_data(struct svc_channels_t* svc_channels,
                  uint16_t channel_id,
                  void* data, uint32_t bytes);
   
#endif
