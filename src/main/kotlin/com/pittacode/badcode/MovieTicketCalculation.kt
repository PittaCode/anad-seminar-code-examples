package com.pittacode.badcode

import java.time.DayOfWeek
import java.time.DayOfWeek.SATURDAY
import java.time.DayOfWeek.SUNDAY
import java.time.DayOfWeek.TUESDAY
import java.time.DayOfWeek.WEDNESDAY
import kotlin.math.ceil

private const val WEEKEND_BASE_PRICE = 50.0
private const val WEEKDAY_BASE_PRICE = 40.0

fun calculateTicketPrice(request: MovieTicketRequest): Double {
    var basePrice = calculateBasePriceBasedOnDay(request)


    if (request.isForChild() && request.isOnWeekend()) {
        basePrice /= 2
    }

    val reduction = calculateReductionBasedOnDay(request)
    val finalPrice = basePrice * (1 - reduction / 100.0)
    return ceil(finalPrice)
}

private fun calculateBasePriceBasedOnDay(request: MovieTicketRequest): Double {
    return if (request.isOnWeekend()) WEEKEND_BASE_PRICE
    else WEEKDAY_BASE_PRICE
}

private fun MovieTicketRequest.isOnWeekend(): Boolean {
    return isOnDay(SATURDAY, SUNDAY)
}

private fun MovieTicketRequest.isForChild(): Boolean {
    return age < 10
}

private fun calculateReductionBasedOnDay(request: MovieTicketRequest): Int {
    return if (request.isOnDay(TUESDAY, WEDNESDAY)) 25
    else 0
}

private fun MovieTicketRequest.isOnDay(vararg days: DayOfWeek): Boolean {
    return date.dayOfWeek in days
}

data class MovieTicketRequest(val age: Int, val date: Date)
data class Date(val dayOfWeek: DayOfWeek)


