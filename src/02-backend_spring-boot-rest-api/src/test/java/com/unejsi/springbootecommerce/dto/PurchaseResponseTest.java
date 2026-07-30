package com.unejsi.springbootecommerce.dto;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class PurchaseResponseTest {

    @Test
    void constructor_ShouldSetTrackingNumber() {
        String trackingNumber = UUID.randomUUID().toString();
        PurchaseResponse response = new PurchaseResponse(trackingNumber);

        assertEquals(trackingNumber, response.getOrderTrackingNumber());
    }

    @Test
    void getOrderTrackingNumber_ShouldNotBeNull() {
        PurchaseResponse response = new PurchaseResponse("TRACK-12345");

        assertNotNull(response.getOrderTrackingNumber());
    }

    @Test
    void getOrderTrackingNumber_ShouldReturnCorrectValue() {
        PurchaseResponse response = new PurchaseResponse("ORDER-ABC-98765");

        assertEquals("ORDER-ABC-98765", response.getOrderTrackingNumber());
    }

    @Test
    void constructor_WithEmptyString_ShouldWork() {
        PurchaseResponse response = new PurchaseResponse("");

        assertEquals("", response.getOrderTrackingNumber());
    }
}
