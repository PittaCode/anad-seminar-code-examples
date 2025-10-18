package com.pittacode.badcode

import java.time.DayOfWeek
import java.time.DayOfWeek.SATURDAY
import java.time.DayOfWeek.SUNDAY
import java.time.DayOfWeek.TUESDAY
import java.time.DayOfWeek.WEDNESDAY
import kotlin.math.ceil

// Base prices
private const val WEEKDAY_BASE_PRICE = 40.0
private const val WEEKEND_BASE_PRICE = 50.0

// Discounts
private const val DISCOUNT_RATE = 0.25
private const val NO_DISCOUNT = 0.0
private const val CHILD_DISCOUNT_FACTOR = 0.5
private const val MAX_CHILD_AGE = 10

fun calculateTicketPrice(request: MovieTicketRequest): Double {
    val basePrice = calculateBasePrice(request)
    val discountFactor = calculateDiscountFactor(request)
    return ceil(basePrice * discountFactor)
}

private fun calculateBasePrice(request: MovieTicketRequest): Double {
    return if (request.isOnWeekend()) {
        if (request.isForChild()) WEEKEND_BASE_PRICE * CHILD_DISCOUNT_FACTOR
        else WEEKEND_BASE_PRICE
    } else {
        WEEKDAY_BASE_PRICE
    }
}

private fun MovieTicketRequest.isOnWeekend(): Boolean {
    return isOnDay(SATURDAY, SUNDAY)
}

private fun MovieTicketRequest.isForChild(): Boolean {
    return age < MAX_CHILD_AGE
}

private fun calculateDiscountFactor(request: MovieTicketRequest): Double {
    val discountRate = if (request.isOnDay(TUESDAY, WEDNESDAY)) DISCOUNT_RATE
    else NO_DISCOUNT
    return 1 - discountRate
}

private fun MovieTicketRequest.isOnDay(vararg days: DayOfWeek): Boolean {
    return date.dayOfWeek in days
}

data class MovieTicketRequest(val age: Int, val date: Date)
data class Date(val dayOfWeek: DayOfWeek)


