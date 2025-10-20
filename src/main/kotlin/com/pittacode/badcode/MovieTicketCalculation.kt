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
private const val CHILD_DISCOUNT_RATE = 0.5
private const val NO_DISCOUNT = 0.0
private const val MAX_CHILD_AGE = 10

fun calculateTicketPrice(request: MovieTicketRequest): Double {
    val basePrice = calculateBasePrice(request)
    val discountFactor = calculateDiscountFactor(request)
    return ceil(basePrice * discountFactor)
}

private fun calculateBasePrice(request: MovieTicketRequest): Double =
    if (request.isOnWeekend()) WEEKEND_BASE_PRICE
    else WEEKDAY_BASE_PRICE

private fun calculateDiscountFactor(request: MovieTicketRequest): Double =
    1 - calculateDiscountRate(request)

private fun calculateDiscountRate(request: MovieTicketRequest): Double =
    if (request.isOnDay(TUESDAY, WEDNESDAY)) DISCOUNT_RATE
    else if (request.isOnWeekend() && request.isForChild()) CHILD_DISCOUNT_RATE
    else NO_DISCOUNT

private fun MovieTicketRequest.isOnWeekend(): Boolean =
    isOnDay(SATURDAY, SUNDAY)

private fun MovieTicketRequest.isOnDay(vararg days: DayOfWeek): Boolean =
    date.dayOfWeek in days

private fun MovieTicketRequest.isForChild(): Boolean =
    age < MAX_CHILD_AGE

data class MovieTicketRequest(val age: Int, val date: Date)
data class Date(val dayOfWeek: DayOfWeek)


