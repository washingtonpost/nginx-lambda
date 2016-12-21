#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>

static char *ngx_http_lambda(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);
static ngx_int_t ngx_http_lambda_handler(ngx_http_request_t *req);
static void * ngx_http_lambda_create_loc_conf(ngx_conf_t *cf);

/**
 * This module provided directive: lambda.
 *
 */
static ngx_command_t ngx_http_lambda_commands[] = {
    { 
        ngx_string("lambda"), /* directive */
        NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1, /* location context and takes 1 argument the lambda function ARN */
        ngx_http_lambda, /* configuration setup function */
        0, /* No offset. Only one context is supported. */
        0, /* No offset when storing the module configuration on struct. */
        NULL
    },
    ngx_null_command /* command termination */
};

/* The module context. */
static ngx_http_module_t ngx_http_lambda_module_ctx = {
    NULL, /* preconfiguration */
    NULL, /* postconfiguration */

    NULL, /* create main configuration */
    NULL, /* init main configuration */

    NULL, /* create server configuration */
    NULL, /* merge server configuration */

    ngx_http_lambda_create_loc_conf, /* create location configuration */
    NULL /* merge location configuration */
};

/* Module definition. */
ngx_module_t ngx_http_lambda_module = {
    NGX_MODULE_V1,
    &ngx_http_lambda_module_ctx, /* module context */
    ngx_http_lambda_commands, /* module directives */
    NGX_HTTP_MODULE, /* module type */
    NULL, /* init master */
    NULL, /* init module */
    NULL, /* init process */
    NULL, /* init thread */
    NULL, /* exit thread */
    NULL, /* exit process */
    NULL, /* exit master */
    NGX_MODULE_V1_PADDING
};

typedef struct {
    ngx_str_t arn;
} ngx_http_lambda_loc_conf_t;

static void * ngx_http_lambda_create_loc_conf(ngx_conf_t *cf)
{
    ngx_http_core_loc_conf_t * conf;
    conf = ngx_pcalloc(cf->pool, sizeof(ngx_http_lambda_loc_conf_t));
    if (conf == NULL) {
        return NULL;
    }

    return conf;
}

/**
 * Configuration setup function that installs the content handler.
 *
 * @param cf
 *   Module configuration structure pointer.
 * @param cmd
 *   Module directives structure pointer.
 * @param conf
 *   Module configuration structure pointer.
 * @return string
 *   Status of the configuration setup.
 */
static char * ngx_http_lambda(ngx_conf_t *cf, ngx_command_t *cmd, void *conf)
{
    ngx_http_core_loc_conf_t *clcf; /* pointer to core location configuration */

    /* Install the handler. */
    clcf = ngx_http_conf_get_module_loc_conf(cf, ngx_http_core_module);
    clcf->handler = ngx_http_lambda_handler;

    return NGX_CONF_OK;
} 

static u_char ngx_lambda_stub[] = "{\"statusCode\": 200, \"headers\": { \"Host\": \"localhost\" }, \"body\": \"hello world\" }";

/**
 * Content handler.
 *
 * @param r
 *   Pointer to the request structure. See http_request.h.
 * @return
 *   The status of the response generation.
 */
static ngx_int_t ngx_http_lambda_handler(ngx_http_request_t *req)
{
    ngx_buf_t *buf;
    ngx_chain_t out;

    /* we response to 'GET' requests only, for now */
    if (!(req->method & NGX_HTTP_GET)) {
        return NGX_HTTP_NOT_ALLOWED;
    }

    /* Set the Content-Type header. */
    req->headers_out.content_type.len = sizeof("application/json") - 1;
    req->headers_out.content_type.data = (u_char *) "application/json";

    /* Allocate a new buffer for sending out the reply. */
    buf = ngx_pcalloc(req->pool, sizeof(ngx_buf_t));

    /* Insertion in the buffer chain. */
    out.buf = buf;
    out.next = NULL; /* just one buffer */

    buf->pos = ngx_lambda_stub; /* first position in memory of the data */
    buf->last = ngx_lambda_stub + sizeof(ngx_lambda_stub); /* last position in memory of the data */
    buf->memory = 1; /* content is in read-only memory */
    buf->last_buf = 1; /* there will be no more buffers in the request */

    /* Sending the headers for the reply. */
    req->headers_out.status = NGX_HTTP_OK; /* 200 status code */
    /* Get the content length of the body. */
    req->headers_out.content_length_n = sizeof(ngx_lambda_stub) - 1;
    ngx_http_send_header(req); /* Send the headers */

    /* Send the body, and return the status code of the output filter chain. */
    return ngx_http_output_filter(req, &out);
}
