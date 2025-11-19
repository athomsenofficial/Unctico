// TaxCalculator.swift
// Comprehensive tax calculations for self-employed massage therapists

import Foundation
import Combine

/// Handles all tax calculations including quarterly estimates, self-employment tax, and deductions
class TaxCalculator: ObservableObject {

    let incomeManager: IncomeManager
    let expenseManager: ExpenseManager

    init(incomeManager: IncomeManager, expenseManager: ExpenseManager) {
        self.incomeManager = incomeManager
        self.expenseManager = expenseManager
    }

    // MARK: - Quarterly Estimated Tax

    /// Calculate quarterly estimated tax payment
    func calculateQuarterlyEstimatedTax(
        quarter: Int,
        year: Int,
        filingStatus: FilingStatus = .single,
        includeStateTax: Bool = false,
        stateRate: Decimal = 0.05
    ) -> QuarterlyTaxEstimate {
        // Get income and expenses for the quarter
        let quarterDates = getQuarterDates(quarter: quarter, year: year)
        let income = incomeManager.totalIncome(from: quarterDates.start, to: quarterDates.end)
        let expenses = expenseManager.totalExpenses(from: quarterDates.start, to: quarterDates.end)

        // Calculate net profit
        let netProfit = income - expenses

        // Calculate self-employment tax
        let seTax = calculateSelfEmploymentTax(netProfit: netProfit)

        // Calculate deductible SE tax (50% of SE tax)
        let deductibleSETax = seTax * 0.5

        // Adjust net profit for deductible SE tax
        let adjustedProfit = netProfit - deductibleSETax

        // Calculate federal income tax
        let federalIncomeTax = calculateIncomeTax(
            taxableIncome: adjustedProfit,
            filingStatus: filingStatus
        )

        // Total federal tax
        let totalFederalTax = federalIncomeTax + seTax

        // State tax (if applicable)
        let stateTax = includeStateTax ? adjustedProfit * stateRate : 0

        // Total tax
        let totalTax = totalFederalTax + stateTax

        // Quarterly payment (divide by 4)
        let quarterlyPayment = totalTax / 4

        return QuarterlyTaxEstimate(
            quarter: quarter,
            year: year,
            grossIncome: income,
            expenses: expenses,
            netProfit: netProfit,
            selfEmploymentTax: seTax,
            federalIncomeTax: federalIncomeTax,
            stateTax: stateTax,
            totalAnnualTax: totalTax,
            quarterlyPayment: quarterlyPayment
        )
    }

    /// Calculate year-to-date estimated tax
    func calculateYearToDateEstimatedTax(
        year: Int,
        filingStatus: FilingStatus = .single,
        includeStateTax: Bool = false,
        stateRate: Decimal = 0.05
    ) -> AnnualTaxEstimate {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endDate = Date()

        let income = incomeManager.totalIncome(from: startDate, to: endDate)
        let expenses = expenseManager.totalExpenses(from: startDate, to: endDate)

        let netProfit = income - expenses
        let seTax = calculateSelfEmploymentTax(netProfit: netProfit)
        let deductibleSETax = seTax * 0.5
        let adjustedProfit = netProfit - deductibleSETax

        let federalIncomeTax = calculateIncomeTax(
            taxableIncome: adjustedProfit,
            filingStatus: filingStatus
        )

        let stateTax = includeStateTax ? adjustedProfit * stateRate : 0
        let totalTax = federalIncomeTax + seTax + stateTax

        return AnnualTaxEstimate(
            year: year,
            grossIncome: income,
            expenses: expenses,
            netProfit: netProfit,
            selfEmploymentTax: seTax,
            federalIncomeTax: federalIncomeTax,
            stateTax: stateTax,
            totalTax: totalTax,
            effectiveTaxRate: income > 0 ? (totalTax / income) * 100 : 0
        )
    }

    // MARK: - Self-Employment Tax

    /// Calculate self-employment tax (Social Security + Medicare)
    func calculateSelfEmploymentTax(netProfit: Decimal) -> Decimal {
        guard netProfit > 0 else { return 0 }

        // 2024 Social Security wage base: $168,600
        let socialSecurityWageBase: Decimal = 168600

        // Calculate 92.35% of net profit (SE tax base)
        let seTaxBase = netProfit * 0.9235

        // Social Security tax (12.4% on earnings up to wage base)
        let socialSecurityTaxableAmount = min(seTaxBase, socialSecurityWageBase)
        let socialSecurityTax = socialSecurityTaxableAmount * 0.124

        // Medicare tax (2.9% on all earnings)
        let medicareTax = seTaxBase * 0.029

        // Additional Medicare tax (0.9% on earnings over $200,000 for single filers)
        let additionalMedicareTax: Decimal
        if seTaxBase > 200000 {
            additionalMedicareTax = (seTaxBase - 200000) * 0.009
        } else {
            additionalMedicareTax = 0
        }

        return socialSecurityTax + medicareTax + additionalMedicareTax
    }

    // MARK: - Income Tax

    /// Calculate federal income tax based on 2024 tax brackets
    func calculateIncomeTax(
        taxableIncome: Decimal,
        filingStatus: FilingStatus
    ) -> Decimal {
        guard taxableIncome > 0 else { return 0 }

        let brackets = getTaxBrackets(filingStatus: filingStatus)
        var tax: Decimal = 0
        var previousLimit: Decimal = 0

        for bracket in brackets {
            if taxableIncome <= previousLimit {
                break
            }

            let taxableInBracket: Decimal
            if let limit = bracket.upperLimit {
                taxableInBracket = min(taxableIncome - previousLimit, limit - previousLimit)
            } else {
                taxableInBracket = taxableIncome - previousLimit
            }

            tax += taxableInBracket * bracket.rate
            previousLimit = bracket.upperLimit ?? taxableIncome
        }

        return tax
    }

    /// Get tax brackets for filing status (2024)
    private func getTaxBrackets(filingStatus: FilingStatus) -> [TaxBracket] {
        switch filingStatus {
        case .single:
            return [
                TaxBracket(rate: 0.10, upperLimit: 11600),
                TaxBracket(rate: 0.12, upperLimit: 47150),
                TaxBracket(rate: 0.22, upperLimit: 100525),
                TaxBracket(rate: 0.24, upperLimit: 191950),
                TaxBracket(rate: 0.32, upperLimit: 243725),
                TaxBracket(rate: 0.35, upperLimit: 609350),
                TaxBracket(rate: 0.37, upperLimit: nil)
            ]

        case .marriedFilingJointly:
            return [
                TaxBracket(rate: 0.10, upperLimit: 23200),
                TaxBracket(rate: 0.12, upperLimit: 94300),
                TaxBracket(rate: 0.22, upperLimit: 201050),
                TaxBracket(rate: 0.24, upperLimit: 383900),
                TaxBracket(rate: 0.32, upperLimit: 487450),
                TaxBracket(rate: 0.35, upperLimit: 731200),
                TaxBracket(rate: 0.37, upperLimit: nil)
            ]

        case .marriedFilingSeparately:
            return [
                TaxBracket(rate: 0.10, upperLimit: 11600),
                TaxBracket(rate: 0.12, upperLimit: 47150),
                TaxBracket(rate: 0.22, upperLimit: 100525),
                TaxBracket(rate: 0.24, upperLimit: 191950),
                TaxBracket(rate: 0.32, upperLimit: 243725),
                TaxBracket(rate: 0.35, upperLimit: 365600),
                TaxBracket(rate: 0.37, upperLimit: nil)
            ]

        case .headOfHousehold:
            return [
                TaxBracket(rate: 0.10, upperLimit: 16550),
                TaxBracket(rate: 0.12, upperLimit: 63100),
                TaxBracket(rate: 0.22, upperLimit: 100500),
                TaxBracket(rate: 0.24, upperLimit: 191950),
                TaxBracket(rate: 0.32, upperLimit: 243700),
                TaxBracket(rate: 0.35, upperLimit: 609350),
                TaxBracket(rate: 0.37, upperLimit: nil)
            ]
        }
    }

    // MARK: - Deductions

    /// Calculate standard deduction for filing status (2024)
    func standardDeduction(filingStatus: FilingStatus) -> Decimal {
        switch filingStatus {
        case .single: return 14600
        case .marriedFilingJointly: return 29200
        case .marriedFilingSeparately: return 14600
        case .headOfHousehold: return 21900
        }
    }

    /// Calculate qualified business income (QBI) deduction (Section 199A)
    func calculateQBIDeduction(netProfit: Decimal) -> Decimal {
        // Simplified QBI deduction (20% of qualified business income)
        // Note: Full calculation has income thresholds and limitations
        return netProfit * 0.20
    }

    /// Calculate home office deduction (simplified method)
    func calculateHomeOfficeDeduction(squareFeet: Int) -> Decimal {
        // Simplified method: $5 per square foot, max 300 sq ft
        let allowedSquareFeet = min(squareFeet, 300)
        return Decimal(allowedSquareFeet * 5)
    }

    // MARK: - Helper Methods

    private func getQuarterDates(quarter: Int, year: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startMonth = (quarter - 1) * 3 + 1

        let start = calendar.date(from: DateComponents(year: year, month: startMonth, day: 1))!
        let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start)!

        return (start, end)
    }

    /// Get effective tax rate
    func effectiveTaxRate(totalTax: Decimal, grossIncome: Decimal) -> Decimal {
        guard grossIncome > 0 else { return 0 }
        return (totalTax / grossIncome) * 100
    }
}

// MARK: - Tax Structures

struct QuarterlyTaxEstimate {
    let quarter: Int
    let year: Int
    let grossIncome: Decimal
    let expenses: Decimal
    let netProfit: Decimal
    let selfEmploymentTax: Decimal
    let federalIncomeTax: Decimal
    let stateTax: Decimal
    let totalAnnualTax: Decimal
    let quarterlyPayment: Decimal
}

struct AnnualTaxEstimate {
    let year: Int
    let grossIncome: Decimal
    let expenses: Decimal
    let netProfit: Decimal
    let selfEmploymentTax: Decimal
    let federalIncomeTax: Decimal
    let stateTax: Decimal
    let totalTax: Decimal
    let effectiveTaxRate: Decimal
}

struct TaxBracket {
    let rate: Decimal
    let upperLimit: Decimal?
}

enum FilingStatus: String, Codable, CaseIterable {
    case single = "Single"
    case marriedFilingJointly = "Married Filing Jointly"
    case marriedFilingSeparately = "Married Filing Separately"
    case headOfHousehold = "Head of Household"
}
