package com.pittacode.badcode

import java.time.DayOfWeek
import kotlin.math.ceil

fun calculateTicketPrice(request: MovieTicketRequest): Double {
    var basePrice = 40.0

    if (request.isOnWeekend()) {
        basePrice = 50.0
    }

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

private fun MovieTicketRequest.isOnWeekend(): Boolean {
    return date.dayOfWeek == DayOfWeek.SATURDAY || date.dayOfWeek == DayOfWeek.SUNDAY
}

data class MovieTicketRequest(val age: Int, val date: Date)
data class Date(val dayOfWeek: DayOfWeek)


