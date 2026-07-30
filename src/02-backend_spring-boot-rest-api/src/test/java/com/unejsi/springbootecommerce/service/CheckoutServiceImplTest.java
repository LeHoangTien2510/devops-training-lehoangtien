package com.unejsi.springbootecommerce.service;

import com.unejsi.springbootecommerce.dao.CustomerRepository;
import com.unejsi.springbootecommerce.dto.Purchase;
import com.unejsi.springbootecommerce.dto.PurchaseResponse;
import com.unejsi.springbootecommerce.entity.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CheckoutServiceImplTest {

    @Mock
    private CustomerRepository customerRepository;

    @InjectMocks
    private CheckoutServiceImpl checkoutService;

    private Purchase purchase;
    private Customer customer;

    @BeforeEach
    void setUp() {
        // Tạo Customer
        customer = new Customer();
        customer.setFirstName("Nguyen");
        customer.setLastName("Van A");
        customer.setEmail("nguyenvana@example.com");

        // Tạo Address
        Address shippingAddress = new Address();
        shippingAddress.setCity("Ho Chi Minh");
        shippingAddress.setCountry("Vietnam");
        shippingAddress.setState("HCM");
        shippingAddress.setStreet("123 Nguyen Hue");
        shippingAddress.setZipCode("700000");

        Address billingAddress = new Address();
        billingAddress.setCity("Ho Chi Minh");
        billingAddress.setCountry("Vietnam");
        billingAddress.setState("HCM");
        billingAddress.setStreet("123 Nguyen Hue");
        billingAddress.setZipCode("700000");

        // Tạo Order
        Order order = new Order();
        order.setTotalQuantity(2);
        order.setTotalPrice(new BigDecimal("500000"));
        order.setStatus("PENDING");

        // Tạo OrderItem
        OrderItem item1 = new OrderItem();
        item1.setImageUrl("img1.jpg");
        item1.setQuantity(1);
        item1.setUnitPrice(new BigDecimal("250000"));
        item1.setProductsId(1L);

        // Tạo Purchase
        purchase = new Purchase();
        purchase.setCustomer(customer);
        purchase.setShippingAddress(shippingAddress);
        purchase.setBillingAddress(billingAddress);
        purchase.setOrder(order);
        purchase.setOrderItems(new HashSet<>(Set.of(item1)));
    }

    @Test
    void placeOrder_NewCustomer_ShouldReturnTrackingNumber() {
        // Arrange: customer chưa tồn tại
        when(customerRepository.findByEmail("nguyenvana@example.com")).thenReturn(null);
        when(customerRepository.save(any(Customer.class))).thenReturn(customer);

        // Act
        PurchaseResponse response = checkoutService.placeOrder(purchase);

        // Assert
        assertNotNull(response);
        assertNotNull(response.getOrderTrackingNumber());
        assertFalse(response.getOrderTrackingNumber().isEmpty());
        // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (36 ký tự)
        assertEquals(36, response.getOrderTrackingNumber().length());
        verify(customerRepository, times(1)).save(any(Customer.class));
    }

    @Test
    void placeOrder_ExistingCustomer_ShouldReuseCustomer() {
        // Arrange: customer đã tồn tại
        Customer existingCustomer = new Customer();
        existingCustomer.setId(1L);
        existingCustomer.setFirstName("Nguyen");
        existingCustomer.setLastName("Van A");
        existingCustomer.setEmail("nguyenvana@example.com");

        when(customerRepository.findByEmail("nguyenvana@example.com")).thenReturn(existingCustomer);
        when(customerRepository.save(any(Customer.class))).thenReturn(existingCustomer);

        // Act
        PurchaseResponse response = checkoutService.placeOrder(purchase);

        // Assert
        assertNotNull(response);
        assertNotNull(response.getOrderTrackingNumber());
        verify(customerRepository, times(1)).findByEmail("nguyenvana@example.com");
        verify(customerRepository, times(1)).save(any(Customer.class));
    }

    @Test
    void placeOrder_ShouldSetOrderRelations() {
        // Arrange
        when(customerRepository.findByEmail(any())).thenReturn(null);
        when(customerRepository.save(any(Customer.class))).thenReturn(customer);

        // Act
        checkoutService.placeOrder(purchase);

        // Assert: order phải có tracking number, billing, shipping address
        assertNotNull(purchase.getOrder().getOrderTrackingNumber());
        assertNotNull(purchase.getOrder().getBillingAddress());
        assertNotNull(purchase.getOrder().getShippingAddress());
    }

    @Test
    void placeOrder_ShouldGenerateUniqueTrackingNumbers() {
        when(customerRepository.findByEmail(any())).thenReturn(null);
        when(customerRepository.save(any(Customer.class))).thenReturn(customer);

        PurchaseResponse response1 = checkoutService.placeOrder(purchase);
        PurchaseResponse response2 = checkoutService.placeOrder(purchase);

        // 2 lần đặt hàng phải có tracking number khác nhau
        assertNotEquals(response1.getOrderTrackingNumber(), response2.getOrderTrackingNumber());
    }
}
