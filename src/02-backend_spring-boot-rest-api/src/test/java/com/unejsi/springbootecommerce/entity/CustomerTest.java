package com.unejsi.springbootecommerce.entity;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CustomerTest {

    @Test
    void add_ValidOrder_ShouldAddOrderAndSetCustomer() {
        Customer customer = new Customer();
        customer.setFirstName("Tran");
        customer.setLastName("Thi B");
        customer.setEmail("tranthib@example.com");

        Order order = new Order();
        order.setStatus("PENDING");

        customer.add(order);

        // Assert: order được thêm vào customer
        assertEquals(1, customer.getOrders().size());
        assertTrue(customer.getOrders().contains(order));
        // Assert: order.customer = customer (bidirectional)
        assertEquals(customer, order.getCustomer());
    }

    @Test
    void add_NullOrder_ShouldNotThrowException() {
        Customer customer = new Customer();
        customer.setEmail("test@example.com");

        // Không được throw exception khi add(null)
        assertDoesNotThrow(() -> customer.add(null));
        assertTrue(customer.getOrders().isEmpty());
    }

    @Test
    void add_MultipleOrders_ShouldAllBeAdded() {
        Customer customer = new Customer();
        customer.setEmail("multi@example.com");

        Order order1 = new Order();
        Order order2 = new Order();
        Order order3 = new Order();

        customer.add(order1);
        customer.add(order2);
        customer.add(order3);

        assertEquals(3, customer.getOrders().size());
    }

    @Test
    void add_DuplicateOrder_ShouldNotDuplicate() {
        Customer customer = new Customer();
        customer.setEmail("dup@example.com");

        Order order = new Order();
        customer.add(order);
        customer.add(order); // thêm lần 2

        // Set không chứa duplicate
        assertEquals(1, customer.getOrders().size());
    }

    @Test
    void getEmail_ShouldReturnCorrectEmail() {
        Customer customer = new Customer();
        customer.setEmail("test@example.com");

        assertEquals("test@example.com", customer.getEmail());
    }

    @Test
    void getFullName_ShouldReturnCorrectName() {
        Customer customer = new Customer();
        customer.setFirstName("Le");
        customer.setLastName("Hoang Tien");

        assertEquals("Le", customer.getFirstName());
        assertEquals("Hoang Tien", customer.getLastName());
    }
}
