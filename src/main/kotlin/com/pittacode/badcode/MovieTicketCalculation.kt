package com.pittacode.badcode

import java.time.DayOfWeek
import kotlin.math.ceil

private const val WEEKEND_BASE_PRICE = 50.0
private const val WEEKDAY_BASE_PRICE = 40.0

fun calculateTicketPrice(request: MovieTicketRequest): Double {
    var basePrice = calculateBasePriceBasedOnDay(request)

    var reduction = 0
    if (request.date.dayOfWeek == DayOfWeek.TUESDAY || request.date.dayOfWeek == DayOfWeek.WEDNESDAY) {
        reduction = 25
    }

    if (request.age < 10) {
        if (request.isOnWeekend()) {
            basePrice /= 2
        }

        val finalPriceChildren = basePrice * (1 - reduction / 100.0)
        return ceil(basePrice)
    }

    val finalPrice = basePrice * (1 - reduction / 100.0)
    return ceil(finalPrice)
}

private fun calculateBasePriceBasedOnDay(request: MovieTicketRequest): Double {
    return if (request.isOnWeekend()) WEEKEND_BASE_PRICE
    else WEEKDAY_BASE_PRICE
}

private fun MovieTicketRequest.isOnWeekend(): Boolean {
    return date.dayOfWeek == DayOfWeek.SATURDAY || date.dayOfWeek == DayOfWeek.SUNDAY
}

data class MovieTicketRequest(val age: Int, val date: Date)
data class Date(val dayOfWeek: DayOfWeek)


