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
 * Original author:  Rajesh Nambiar   <rajesh.nambiarr@seagate.com>
 * Original author:  Kaustubh Deorukhkar   <kaustubh.deorukhkar@seagate.com>
 * Original creation date: 09-Nov-2015
 */

#pragma once

#ifndef __MERO_FE_S3_UT_MOCK_S3_REQUEST_OBJECT_H__
#define __MERO_FE_S3_UT_MOCK_S3_REQUEST_OBJECT_H__

#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "s3_request_object.h"

class MockS3RequestObject : public S3RequestObject {
  public:
  MockS3RequestObject(evhtp_request_t *req) : S3RequestObject(req) {}
  MOCK_METHOD0(c_get_full_path, const char *());
  MOCK_METHOD0(get_host_header, std::string());
  MOCK_METHOD0(http_verb, S3HttpVerb());
  MOCK_METHOD0(c_get_uri_query, const char *());
  MOCK_METHOD0(get_evbase, struct event_base*());
  MOCK_METHOD0(get_request, evhtp_request_t *());
  MOCK_METHOD1(has_query_param_key, bool(std::string key));
  MOCK_METHOD1(set_bucket_name, void(std::string& name));
  MOCK_METHOD1(set_object_name, void(std::string& name));
};

#endif