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
 * Original author:  Arjun Hariharan <arjun.hariharan@seagate.com>
 * Original creation date: 12-Nov-2015
 */
package com.seagates3.validator;

import java.util.Map;
import java.util.TreeMap;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import org.junit.Before;
import org.junit.Test;

public class UserValidatorTest {
    UserValidator userValidator;
    Map requestBody;

    public UserValidatorTest() {
        userValidator = new UserValidator();
    }

    @Before
    public void setUp() {
        requestBody = new TreeMap();
    }

    /**
     * Test User#create.
     * Case - User name is not provided.
     */
    @Test
    public void Create_UserNameNull_False() {
        assertFalse(userValidator.create(requestBody));
    }

    /**
     * Test User#create.
     * Case - User name is valid , Path is not provided.
     */
    @Test
    public void Create_ValidUserNameAndPathEmpty_True() {
        requestBody.put("UserName", "root");
        assertTrue(userValidator.create(requestBody));
    }

    /**
     * Test User#create.
     * Case - User name and path are valid.
     */
    @Test
    public void Create_ValidUserNameAndPath_True() {
        requestBody.put("UserName", "root");
        requestBody.put("Path", "/seagate/test/");
        assertTrue(userValidator.create(requestBody));
    }

    /**
     * Test User#create.
     * Case - User name is invalid.
     */
    @Test
    public void Create_InValidUserName_False() {
        requestBody.put("UserName", "root$^");
        assertFalse(userValidator.create(requestBody));
    }

    /**
     * Test User#create.
     * Case - User name is valid, path is invalid.
     */
    @Test
    public void Create_ValidUserNameAndInvalidPath_False() {
        requestBody.put("UserName", "root");
        requestBody.put("Path", "/seagate/test");
        assertFalse(userValidator.create(requestBody));
    }

    /**
     * Test User#delete.
     * Case - User name is not provided.
     */
    @Test
    public void Delete_UserNameNull_False() {
        assertFalse(userValidator.delete(requestBody));
    }

    /**
     * Test User#delete.
     * Case - User name is valid.
     */
    @Test
    public void Delete_ValidUserName_True() {
        requestBody.put("UserName", "root");
        assertTrue(userValidator.delete(requestBody));
    }

    /**
     * Test User#delete.
     * Case - User name is invalid.
     */
    @Test
    public void Delete_InValidUserName_False() {
        requestBody.put("UserName", "root$^");
        assertFalse(userValidator.delete(requestBody));
    }

    /**
     * Test User#update.
     * Case - User name is invalid.
     */
    @Test
    public void Update_InvalidUserName_False() {
        requestBody.put("UserName", "root$^");
        assertFalse(userValidator.update(requestBody));
    }

    /**
     * Test User#update.
     * Case - New user name is invalid.
     */
    @Test
    public void Update_InvalidNewUserName_False() {
        requestBody.put("UserName", "root");
        requestBody.put("NewUserName", "root$^");
        assertFalse(userValidator.update(requestBody));
    }

    /**
     * Test User#update.
     * Case - User name is valid, new user name is valid and new path is invalid.
     */
    @Test
    public void Update_InvalidNewPath_False() {
        requestBody.put("UserName", "root");
        requestBody.put("NewUserName", "root123");
        requestBody.put("NewPath", "seagate/test");
        assertFalse(userValidator.update(requestBody));
    }

    /**
     * Test User#update.
     * Case - valid inputs.
     */
    @Test
    public void Update_ValidInputs_True() {
        requestBody.put("UserName", "root");
        requestBody.put("NewUserName", "root123");
        requestBody.put("NewPath", "/seagate/test/");
        assertTrue(userValidator.update(requestBody));
    }
}
