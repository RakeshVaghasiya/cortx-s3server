
#include <unistd.h>

#include "s3_common.h"

#include "s3_clovis_rw_common.h"
#include "s3_clovis_config.h"
#include "s3_clovis_kvs_reader.h"
#include "s3_uri_to_mero_oid.h"

extern struct m0_clovis_scope     clovis_uber_scope;
extern struct m0_clovis_container clovis_container;

S3ClovisKVSReader::S3ClovisKVSReader(std::shared_ptr<S3RequestObject> req) : request(req), state(S3ClovisKVSReaderOpState::start), iteration_index(0), last_value("") {
  printf("S3ClovisKVSReader created\n");
}

void S3ClovisKVSReader::get_keyval(std::string index_name, std::string key, std::function<void(void)> on_success, std::function<void(void)> on_failed) {
  printf("S3ClovisKVSWriter::get_keyval called with index_name = %s and key = %s\n", index_name.c_str(), key.c_str());

  int rc = 0;

  this->handler_on_success = on_success;
  this->handler_on_failed  = on_failed;

  S3ClovisKVSReaderContext *context = new S3ClovisKVSReaderContext(request, std::bind( &S3ClovisKVSReader::get_keyval_successful, this), std::bind( &S3ClovisKVSReader::get_keyval_failed, this));

  context->init_idx_read_op_ctx(1);
  context->init_kvs_read_op_ctx(1);

  struct s3_clovis_op_context *ctx = context->get_clovis_op_ctx();
  struct s3_clovis_idx_op_context *idx_ctx = context->get_clovis_idx_op_ctx();
  struct s3_clovis_kvs_op_context *kvs_ctx = context->get_clovis_kvs_op_ctx();

  // Remember, so buffers can be iterated.
  clovis_kvs_op_context = kvs_ctx;

  ctx->cbs->ocb_arg = (void *)context;
  ctx->cbs->ocb_executed = NULL;
  ctx->cbs->ocb_stable = s3_clovis_op_stable;
  ctx->cbs->ocb_failed = s3_clovis_op_failed;

  S3UriToMeroOID(index_name.c_str(), &id);

  kvs_ctx->keys->ov_vec.v_count[0] = key.length() + 1;
  kvs_ctx->keys->ov_buf[0] = calloc(1, key.length() + 1);
  memcpy(kvs_ctx->keys->ov_buf[0], (void*)key.c_str(), key.length());
  // TODO - ?? for the sake of it allocate space for value we read.
  // kvs_ctx->values->ov_vec.v_count[0] = 4096;
  // kvs_ctx->values->ov_buf[0] = calloc(1, 4096 + 1);

  m0_clovis_idx_init(idx_ctx->idx, &clovis_container.co_scope, &id);

  rc = m0_clovis_idx_op(idx_ctx->idx, M0_CLOVIS_IC_GET, kvs_ctx->keys, kvs_ctx->values, &(ctx->ops[0]));
  if(rc != 0) {
    printf("m0_clovis_idx_op failed\n");
  }
  else {
    printf("m0_clovis_idx_op suceeded\n");
  }

  m0_clovis_op_setup(ctx->ops[0], ctx->cbs, 0);
  m0_clovis_op_launch(ctx->ops, 1);
}

void S3ClovisKVSReader::get_keyval_successful() {
  printf("S3ClovisKVSReader::get_keyval_successful called\n");
  state = S3ClovisKVSReaderOpState::present;
  last_value = std::string((char*)clovis_kvs_op_context->values->ov_buf[0], clovis_kvs_op_context->values->ov_vec.v_count[0]);
  this->handler_on_success();
}

void S3ClovisKVSReader::get_keyval_failed() {
  printf("S3ClovisKVSReader::get_keyval_failed called\n");
  state = S3ClovisKVSReaderOpState::failed;
  this->handler_on_failed();
}