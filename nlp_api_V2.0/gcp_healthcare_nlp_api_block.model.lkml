connection: "looker-private-demo"

include: "/**/*.view.lkml"          # include all views the project
include: "/**/*.dashboard.lookml"   # include LookML dashboards

persist_for: "24 hours"
label: "GCP Healthcare NLP API"


explore: kaggle_clinical_notes_nlp_results {
  extends: [kaggle_nlp_results_join_logic]
  label: "Kaggle NLP Results - Patient Review"
  #This ensures that no patient in the dataset is over 102 years old.
  #sql_always_where: ${dob_year} >= 2058 AND ${admission_offset_year} >= 1996 AND ${age} > 0 AND ${days_los} >= 0 AND ${dob_offset_year} < 2022;;
}


explore: kaggle_nlp_results_terms {
  extends: [kaggle_nlp_results_join_logic]
  label: "Kaggle NLP Results - Term Review"
  always_filter: { filters:[kaggle_nlp_results_terms.filter_on_original_term: "%cancer%"]}

  join: kaggle_clinical_notes_nlp_results__entities {
    view_label: "(2) NLP Results - Entities" # overriding view label for this explore
  }

  join: kaggle_clinical_notes_nlp_results {
    view_label: "(1) NLP Results - Overview"
    type: left_outer
    sql_on: ${kaggle_nlp_results_terms.observation_id} = ${kaggle_clinical_notes_nlp_results.id}  ;;
    relationship: one_to_many
  }
}


# this is the join logic used to unnest the kaggle_clinical_notes_nlp_results nested fields
explore: kaggle_nlp_results_join_logic {
  extension: required

  join: kaggle_clinical_notes_nlp_results__entities {
    view_label: "(1) NLP Results - Overview"
    sql: LEFT JOIN UNNEST(${kaggle_clinical_notes_nlp_results.entities}) as kaggle_clinical_notes_nlp_results__entities ;;
    relationship: one_to_many
  }

  join: kaggle_clinical_notes_nlp_results__entity_mentions {
    view_label: "(2) NLP Results - Entities"
    sql: LEFT JOIN UNNEST(${kaggle_clinical_notes_nlp_results.entity_mentions}) as kaggle_clinical_notes_nlp_results__entity_mentions ;;
    relationship: one_to_many
  }

  join: kaggle_clinical_notes_nlp_results__relationships {
    view_label: "NLP Results - Relationships"
    sql: LEFT JOIN UNNEST(${kaggle_clinical_notes_nlp_results.relationships}) as kaggle_clinical_notes_nlp_results__relationships ;;
    relationship: one_to_many
  }

  join: kaggle_clinical_notes_nlp_results__entities__vocabulary_codes {
    view_label: "NLP Results - Entities, Vocabulary Codes"
    sql: LEFT JOIN UNNEST(${kaggle_clinical_notes_nlp_results__entities.vocabulary_codes}) as kaggle_clinical_notes_nlp_results__entities__vocabulary_codes ;;
    relationship: one_to_many
  }

  join: kaggle_clinical_notes_nlp_results__entity_mentions__linked_entities {
    view_label: "NLP Results - Entity Mentions, Linked Entities"
    sql: LEFT JOIN UNNEST(${kaggle_clinical_notes_nlp_results__entity_mentions.linked_entities}) as kaggle_clinical_notes_nlp_results__entity_mentions__linked_entities ;;
    relationship: one_to_many
  }

  join: kaggle_nlp_results_vocab {
    view_label: "(2) NLP Results - Entities"
    type: left_outer
    relationship: one_to_many
    sql_on: ${kaggle_nlp_results_vocab.entity_id} = ${kaggle_clinical_notes_nlp_results__entity_mentions__linked_entities.entity_id} ;;
  }
}