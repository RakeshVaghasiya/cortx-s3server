/*
 * Copyright (c) 2020 Seagate Technology LLC and/or its Affiliates
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * For any questions about this software or licensing,
 * please email opensource@seagate.com or cortx-questions@seagate.com.
 *
 */

package com.seagates3.authserver;

import static io.netty.handler.codec.http.HttpHeaders.Names.CONNECTION;
import static io.netty.handler.codec.http.HttpHeaders.Names.CONTENT_LENGTH;
import static io.netty.handler.codec.http.HttpHeaders.Names.CONTENT_TYPE;

import com.seagates3.controller.FaultPointsController;
import com.seagates3.controller.IAMController;
import com.seagates3.controller.SAMLWebSSOController;
import com.seagates3.response.ServerResponse;
import com.seagates3.response.generator.FaultPointsResponseGenerator;
import com.seagates3.response.generator.ResponseGenerator;
import com.seagates3.util.BinaryUtil;

import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.DefaultFullHttpResponse;
import io.netty.handler.codec.http.FullHttpRequest;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpHeaders;
import io.netty.handler.codec.http.HttpVersion;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.seagates3.util.BinaryUtil;

public class AuthServerPostHandler {

    private final Logger LOGGER = LoggerFactory.getLogger(
            AuthServerHandler.class.getName());

    final ChannelHandlerContext ctx;
    final FullHttpRequest httpRequest;
    final Boolean keepAlive;

    public AuthServerPostHandler(ChannelHandlerContext ctx,
            FullHttpRequest httpRequest) {
        this.httpRequest = httpRequest;
        this.ctx = ctx;
        keepAlive = HttpHeaders.isKeepAlive(httpRequest);
    }

    public void run() {
        Map<String, String> requestBody = getHttpRequestBodyAsMap();

        // Check if Request_uid is present in request body
        // This is when the request is received from S3
        String reqId = null;
        if (requestBody != null) reqId = requestBody.get("Request_uid");
        if (reqId != null && !reqId.isEmpty()) {
          AuthServerConfig.setReqId(reqId);
          // Else check if Request_Id is present in request header
          // In case the reqest is received directly from HAProxy
        } else {
          if (httpRequest.headers() != null)
            reqId = httpRequest.headers().get("Request_uid");
          if (reqId != null && !reqId.isEmpty()) {
            AuthServerConfig.setReqId(reqId);
          } else {  // Else generate a new ID and set
            AuthServerConfig.setReqId(BinaryUtil.getAlphaNumericUUID());
          }
        }

        if (httpRequest.getUri().startsWith("/saml")) {
            LOGGER.debug("Calling SAML WebSSOControler.");
            FullHttpResponse response = new SAMLWebSSOController(requestBody)
                    .samlSignIn();
            returnHTTPResponse(response);
        } else {
            ServerResponse serverResponse;
            String action = requestBody.get("Action");
            if (action == null) {
                LOGGER.debug("Request action can not be null.");
                returnHTTPResponse(new ResponseGenerator().badRequest());
                return;
            }
            LOGGER.debug("Requested action: " + action);
            if (isFiRequest(action)) {
                serverResponse = serveFiRequest(requestBody);
            } else {
                serverResponse = serveIamRequest(requestBody);
            }

            returnHTTPResponse(serverResponse);
        }
    }

    /**
     * Read the requestResponse object and send the response to the client.
     */
    private void returnHTTPResponse(ServerResponse requestResponse) {
        String responseBody = requestResponse.getResponseBody();
        FullHttpResponse response = new DefaultFullHttpResponse(HttpVersion.HTTP_1_1,
                requestResponse.getResponseStatus(),
                Unpooled.wrappedBuffer(responseBody.getBytes(StandardCharsets.UTF_8))
        );
        response.headers().set(CONTENT_TYPE, "text/xml");
        response.headers().set(CONTENT_LENGTH, response.content().readableBytes());

        returnHTTPResponse(response);
    }

    private void returnHTTPResponse(FullHttpResponse response) {

        LOGGER.info("Sending HTTP Response code [" +
                               response.getStatus() + "]");

        if (!keepAlive) {
            ctx.write(response).addListener(ChannelFutureListener.CLOSE);

            LOGGER.debug("Response sent successfully.");
            LOGGER.debug("Connection closed.");
        } else {
            response.headers().set(CONNECTION, HttpHeaders.Values.KEEP_ALIVE);
            ctx.writeAndFlush(response);

            LOGGER.debug("Response sent successfully.");
            LOGGER.debug("Connection kept alive.");
        }
    }

    private Map<String, String> getHttpRequestBodyAsMap() {
        AuthRequestDecoder decoder = new AuthRequestDecoder(httpRequest);
        return decoder.getRequestBodyAsMap();
    }

    private boolean isFiRequest(String request) {
        return request.equals("InjectFault") || request.equals("ResetFault");
    }

    private ServerResponse serveFiRequest(Map<String, String> requestBody) {
        FaultPointsController faultPointsController;
        ServerResponse serverResponse;

        if (!AuthServerConfig.isFaultInjectionEnabled()) {
            serverResponse = new FaultPointsResponseGenerator()
                    .badRequest("Fault injection is disabled. Invalid request.");
        } else {
            faultPointsController = new FaultPointsController();
            if (requestBody.get("Action").equals("InjectFault")) {
                serverResponse = faultPointsController.set(requestBody);
            } else {
                serverResponse = faultPointsController.reset(requestBody);
            }
        }

        return serverResponse;
    }

    private ServerResponse serveIamRequest(Map<String, String> requestBody) {
        IAMController iamController = new IAMController();
        return iamController.serve(httpRequest, requestBody);
    }
}
