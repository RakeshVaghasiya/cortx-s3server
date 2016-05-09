/*
 * COPYRIGHT 2015 SEAGATE LLC
 *
 * THIS DRAWING/DOCUMENT, ITS SPECIFICATIONS, AND THE DATA CONTAINED
 * HEREIN, ARE THE EXCLUSIVE PROPERTY OF SEAGATE TECHNOLOGY
 * LIMITED, ISSUED IN STRICT CONFIDENCE AND SHALL NOT, WITHOUT
 * THE PRIOR WRITTEN PERMISSION OF SEAGATE TECHNOLOGY LIMITED,
 * BE REPRODUCED, COPIED, OR DISCLOSED TO A THIRD PARTY, OR
 * USED FOR ANY PURPOSE WHATSOEVER, OR STORED IN A RETRIEVAL SYSTEM
 * EXCEPT AS ALLOWED BY THE TERMS OF SEAGATE LICENSES AND AGREEMENTS.
 *
 * YOU SHOULD HAVE RECEIVED A COPY OF SEAGATE'S LICENSE ALONG WITH
 * THIS RELEASE. IF NOT PLEASE CONTACT A SEAGATE REPRESENTATIVE
 * http://www.seagate.com/contact
 *
 * Original author:  Rajesh Nambiar <rajesh.nambiar@seagate.com>
 * Original author:  Kaustubh Deorukhkar <kaustubh.deorukhkar@seagate.com>
 * Original creation date: 1-Dec-2015
 */

#pragma once

#ifndef __MERO_FE_S3_SERVER_S3_CLOVIS_WRAPPER_H__
#define __MERO_FE_S3_SERVER_S3_CLOVIS_WRAPPER_H__

#include <functional>
#include <iostream>
#include "s3_clovis_rw_common.h"
#include "clovis_helpers.h"

class ClovisAPI {
  public:
    virtual int init_clovis_api(const char *clovis_local_addr,
                            const char *clovis_ha_addr,
                            const char *clovis_confd_addr,
                            const char *clovis_prof,
                            short clovis_layout_id) = 0;

    virtual void clovis_idx_init(struct m0_clovis_idx    *idx, struct m0_clovis_realm  *parent, const struct m0_uint128 *id) = 0;

    virtual void clovis_obj_init(struct m0_clovis_obj     *obj,
                         struct m0_clovis_realm   *parent,
                         const struct m0_uint128  *id) = 0;

    virtual int  clovis_entity_create(struct m0_clovis_entity *entity, struct m0_clovis_op **op) = 0;

    virtual int  clovis_entity_delete(struct m0_clovis_entity *entity, struct m0_clovis_op **op) = 0;

    virtual void clovis_op_setup(struct m0_clovis_op *op, const struct m0_clovis_op_ops *ops, m0_time_t linger) = 0;

    virtual int  clovis_idx_op(struct m0_clovis_idx *idx,
                               enum m0_clovis_idx_opcode opcode,
                               struct m0_bufvec *keys,
                               struct m0_bufvec *vals,
                               struct m0_clovis_op **op) = 0;

    virtual void clovis_obj_op(struct m0_clovis_obj       *obj,
                               enum m0_clovis_obj_opcode   opcode,
                               struct m0_indexvec         *ext,
                               struct m0_bufvec           *data,
                               struct m0_bufvec           *attr,
                               uint64_t                    mask,
                               struct m0_clovis_op       **op) = 0;

    virtual void clovis_op_launch(struct m0_clovis_op **op, uint32_t nr) = 0;
};

class ConcreteClovisAPI : public ClovisAPI {
  public:
    int init_clovis_api(const char *clovis_local_addr,
                        const char *clovis_ha_addr,
                        const char *clovis_confd_addr,
                        const char *clovis_prof,
                        short clovis_layout_id) {
      return init_clovis(clovis_local_addr, clovis_ha_addr, clovis_confd_addr, clovis_prof,clovis_layout_id);
    }

    void clovis_idx_init(struct m0_clovis_idx    *idx, struct m0_clovis_realm  *parent, const struct m0_uint128 *id) {
      m0_clovis_idx_init(idx, parent, id);
    }

    void clovis_obj_init(struct m0_clovis_obj *obj,
                         struct m0_clovis_realm *parent,
                         const struct m0_uint128 *id) {
      m0_clovis_obj_init(obj, parent, id);
    }

    int clovis_entity_create(struct m0_clovis_entity *entity, struct m0_clovis_op **op) {
      return m0_clovis_entity_create(entity, op);
    }

    int clovis_entity_delete(struct m0_clovis_entity *entity, struct m0_clovis_op **op) {
      return m0_clovis_entity_delete(entity, op);
    }

    void clovis_op_setup(struct m0_clovis_op *op, const struct m0_clovis_op_ops *ops, m0_time_t linger)
    {
      m0_clovis_op_setup(op, ops, linger);
    }

    int clovis_idx_op(struct m0_clovis_idx       *idx,
                      enum m0_clovis_idx_opcode   opcode,
                      struct m0_bufvec           *keys,
                      struct m0_bufvec           *vals,
                      struct m0_clovis_op       **op) {
      return m0_clovis_idx_op(idx, opcode, keys, vals, op);
    }

    void clovis_obj_op(struct m0_clovis_obj       *obj,
                       enum m0_clovis_obj_opcode   opcode,
                       struct m0_indexvec         *ext,
                       struct m0_bufvec           *data,
                       struct m0_bufvec           *attr,
                       uint64_t                    mask,
                       struct m0_clovis_op       **op) {
       return m0_clovis_obj_op(obj, opcode, ext, data, attr, mask, op);
    }

    void clovis_op_launch(struct m0_clovis_op **op, uint32_t nr) {
      m0_clovis_op_launch(op, nr);
    }
};
#endif
