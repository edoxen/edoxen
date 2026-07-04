# frozen_string_literal: true

module Edoxen
  # Built-in reference data for ISO codes used across the Edoxen model:
  # ISO 3166-1 alpha-2 country codes, ISO 639-3 language codes, ISO
  # 15924 script codes, UN/LOCODEs, and IATA airport codes.
  #
  # UN/LOCODE lookups delegate to the `unlocodes` gem (the canonical
  # Ruby registry of the UNECE UN/LOCODE dataset).
  # IATA lookups delegate to the `iata` gem (the canonical Ruby registry
  # of the IATA airport code list, sourced from Wikidata).
  #
  # Reference data sources:
  # * https://www.iso.org/iso-3166-country-codes.html
  # * https://iso639-3.sil.org/
  # * https://unicode.org/iso15924/
  # * https://unece.org/trade/cefact/unlocode-code-list-country-and-territory
  # * https://www.wikidata.org/wiki/Property:P238 (IATA airport code)
  module ReferenceData
    require "unlocodes"
    require "iata"

    COUNTRY_CODES = %w[
      AE AF AR AT AU BE BG BR BY CA CH CL CN CO CY CZ DE DK EE ES FI FR
      GB GR HK HR HU ID IE IL IN IS IT JP KE KR LK LT LU LV MT MX MY NL NO PH
      NZ PL PT RO RS RU SA SE SG SI SK TH TN TR TW UA US VN ZA
    ].freeze

    LANGUAGE_CODES = %w[
      ara chi deu eng fra jpn rus spa zho
    ].freeze

    SCRIPT_CODES = %w[
      Arab Cyrl Hans Hant Hang Hebr Jpan Kore Latn
    ].freeze

    UNLOCODES = %w[
      AUMEL ATVIE BEBRU BGSOF BRBSB CHGVA CNCAN CNHKG CNSHA CNXSZ COCTG
      CYLCA CZPRG DEBER DEHAM DEFRA DKCPH ESMAD FIHEL FRARC FRLYS FRMRS
      FRPAR GBLON HKHKG HUBUD IDJKT IEDUB IEORK ILTLV INDEL ISREY ITROM
      JPTYO KEMBA KRSEL LKCMB LVRIX LULUX MYKUL NLRTM NOOSL NZAKL PHMNL
      PLWAW PTLIS ROBUH RSBEG SESTO SGSIN SKBTS THBKK THCNM TRIST TWTPE
      UAIEV USMIA USNYC USORL VNSGN ZACPT
    ].freeze

    class << self
      # Look up a UN/LOCODE entry via the canonical `unlocodes` gem.
      # @param code [String, #to_s] 5-character UN/LOCODE
      # @return [Unlocodes::Entry, nil]
      def find_unlocode(code)
        Unlocodes.find(code.to_s.upcase)
      end

      def unlocode_exists?(code)
        !find_unlocode(code).nil?
      end

      # Look up an IATA airport/city code via the canonical `iata` gem.
      # @param code [String, #to_s] 3-character IATA code
      # @return [Iata::Entry, nil]
      def find_iata(code)
        Iata.find(code.to_s.upcase)
      end

      def iata_exists?(code)
        !find_iata(code).nil?
      end
    end
  end
end
